import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrisync/App Pages/Calendar/AddEventPage.dart';
import 'package:http/http.dart' as http;

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  factory CalendarEvent.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class FarmCalendarPage extends StatefulWidget {
  final String? userCity;
  final Map<String, dynamic>? currentWeather;
  const FarmCalendarPage({Key? key, this.userCity, this.currentWeather})
      : super(key: key);

  @override
  _FarmCalendarPageState createState() => _FarmCalendarPageState();
}

class _FarmCalendarPageState extends State<FarmCalendarPage> {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _firestore
        .collection('farmActivities')
        .doc(user.uid)
        .collection('events')
        .snapshots()
        .listen((snapshot) {
      Map<DateTime, List<CalendarEvent>> eventsMap = {};
      for (var doc in snapshot.docs) {
        final event = CalendarEvent.fromDocument(doc);
        // Only include events for today or future dates.
        if (event.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) continue;
        final dayKey = DateTime(event.date.year, event.date.month, event.date.day);
        eventsMap.putIfAbsent(dayKey, () => []).add(event);
      }
      setState(() {
        _events = eventsMap;
      });
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  // Delete all events for today and future dates
  Future<void> _deleteFutureEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final querySnapshot = await _firestore
        .collection('farmActivities')
        .doc(user.uid)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Generate unique AI tasks for each day from today until end of current month.
  Future<void> _generateMonthlyTasks() async {
    await _deleteFutureEvents();
    setState(() {
      _isLoading = true;
    });
    final user = _auth.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    // Generate tasks for each day from today until the end of the current month.
    DateTime lastDay = DateTime(now.year, now.month + 1, 0);
    List<DateTime> datesToGenerate = [];
    for (DateTime day = today;
        !day.isAfter(lastDay);
        day = day.add(const Duration(days: 1))) {
      datesToGenerate.add(day);
    }

    String weatherInfo = "";
    if (widget.currentWeather != null) {
      weatherInfo =
          "Current weather in ${widget.userCity ?? 'your area'} is ${widget.currentWeather!['weather'][0]['main']} at ${widget.currentWeather!['main']['temp']}°C. ";
    }

    String prompt =
        "You are an expert agricultural advisor. Generate a detailed daily farming plan for the following dates: ${datesToGenerate.map((d) => d.toIso8601String().split('T')[0]).join(', ')}. Use the weather info: $weatherInfo and typical crop data to provide for each day a unique, concise title and actionable recommendation (1-2 sentences) to optimize crop growth. Return the output as a JSON array where each object contains 'date' (YYYY-MM-DD), 'title', and 'description'. Do not include past dates.";

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer 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',
          'HTTP-Referer': 'https://agrisync-app.com',
          'X-Title': 'AgriSync',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-3.2-3b-instruct:free',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
        }),
      );

      List tasks = [];
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiText = data['choices'][0]['message']['content'].trim();
        try {
          tasks = json.decode(aiText);
        } catch (e) {
          // Fallback: generate dummy tasks.
          tasks = [];
          for (var day in datesToGenerate) {
            tasks.add({
              "date": day.toIso8601String().split('T')[0],
              "title": "Farming Task for ${day.month}/${day.day}",
              "description":
                  "Perform specific tasks such as irrigation, fertilization, pest management, and crop monitoring based on current conditions."
            });
          }
        }
      } else {
        tasks = [];
        for (var day in datesToGenerate) {
          tasks.add({
            "date": day.toIso8601String().split('T')[0],
            "title": "Farming Task for ${day.month}/${day.day}",
            "description":
                "Perform specific tasks such as irrigation, fertilization, pest management, and crop monitoring based on current conditions."
          });
        }
      }

      // Save each task as an event
      for (var task in tasks) {
        DateTime taskDate = DateTime.parse(task["date"]);
        // Only add if no event exists for that day with the same title
        final dayKey = DateTime(taskDate.year, taskDate.month, taskDate.day);
        bool exists = _events[dayKey]?.any((e) => e.title == task["title"]) ?? false;
        if (!exists) {
          CalendarEvent event = CalendarEvent(
            id: "",
            title: task["title"],
            description: task["description"],
            date: taskDate,
          );
          await _firestore
              .collection('farmActivities')
              .doc(user.uid)
              .collection('events')
              .add(event.toMap());
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Monthly tasks generated successfully.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating tasks: $e")));
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime firstDay = DateTime(now.year, now.month, 1);
    DateTime lastDay = DateTime(now.year, now.month + 1, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Calendar', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          // AI Generate icon button to generate tasks for the next 3 weeks (current month remaining)
          IconButton(
            icon: const Icon(Icons.event_available, color: Color.fromARGB(255, 66, 192, 201)),
            onPressed: _isLoading ? null : _generateMonthlyTasks,
            tooltip: "Generate Tasks for This Month",
          ),
          // Manual Add Event button
          IconButton(
            icon: const Icon(Icons.add, color: Color.fromARGB(255, 66, 192, 201)),
            onPressed: () {
              // Navigate to your AddEventPage (ensure this page exists in your codebase)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventPage()),
              );
            },
            tooltip: "Add Event",
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // Optionally navigate to a detailed events page if desired.
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color.fromARGB(255, 66, 192, 201),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: const Color.fromARGB(255, 66, 192, 201),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: Colors.black),
              outsideTextStyle: const TextStyle(color: Colors.grey),
            ),
            headerStyle: const HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Color.fromARGB(255, 66, 192, 201)),
              rightChevronIcon: Icon(Icons.chevron_right, color: Color.fromARGB(255, 66, 192, 201)),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _focusedDay).map((event) {
                return ListTile(
                  title: Text(event.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  subtitle: Text(event.description, style: const TextStyle(color: Colors.black)),
                  trailing: Text(
                    "${event.date.day}/${event.date.month}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
