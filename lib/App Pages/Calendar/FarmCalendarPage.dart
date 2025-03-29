import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    if (snapshot.exists) {
      return snapshot.data()!;
    }
    return {};
  }

  Future<void> _deleteFutureEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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

  String extractJson(String text) {
    int start = text.indexOf('[');
    int end = text.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return '';
  }

  Future<void> _generateTasksForNextThreeWeeks() async {
    await _deleteFutureEvents();
    setState(() {
      _isLoading = true;
    });
    final user = _auth.currentUser;
    if (user == null) return;
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    List<DateTime> datesToGenerate = List.generate(21, (i) => today.add(Duration(days: i)));

    final userData = await _fetchUserData();
    String userDataInfo = "";
    if (userData.isNotEmpty) {
      userDataInfo =
          "Farm Size: ${userData['farmSize'] ?? 'N/A'}, Preferred Crops: ${(userData['preferredCrops'] as List?)?.join(', ') ?? 'N/A'}.";
    } else {
      userDataInfo = "Farm Size: 10 acres, Preferred Crops: tomatoes, corn.";
    }

    String weatherInfo = "";
    if (widget.currentWeather != null) {
      weatherInfo =
          "Current weather in ${widget.userCity ?? 'your area'} is ${widget.currentWeather!['weather'][0]['main']} at ${widget.currentWeather!['main']['temp']}°C.";
    } else {
      weatherInfo = "Current weather is typical for the season in your area.";
    }

    String prompt =
        "You are an expert agricultural advisor. Generate a JSON array with 21 unique objects for the next 21 days starting from ${today.toIso8601String().split('T')[0]}. "
        "Each object must contain 'date' (in YYYY-MM-DD format), 'title', and 'description'. "
        "Use the following information to tailor each day's task: Weather Info: $weatherInfo User Data: $userDataInfo. "
        "Ensure that each day's task is distinct, actionable (1-2 sentences), and does not repeat tasks from any other day. "
        "Consider the progression of farming activities over time (e.g., soil preparation, planting, watering, pest control, harvesting). "
        "Return only the JSON array without any additional text or explanations.";

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
        print("AI response: $aiText"); // Log for debugging
        String jsonString = extractJson(aiText);
        if (jsonString.isNotEmpty) {
          try {
            tasks = json.decode(jsonString);
          } catch (e) {
            print("Error parsing JSON: $e");
            tasks = _fallbackTasks(datesToGenerate);
          }
        } else {
          print("No valid JSON found in AI response");
          tasks = _fallbackTasks(datesToGenerate);
        }
      } else {
        print("API failed with status: ${response.statusCode}");
        tasks = _fallbackTasks(datesToGenerate);
      }

      for (var task in tasks) {
        DateTime taskDate = DateTime.parse(task["date"]);
        if (taskDate.isBefore(today)) continue;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI tasks generated successfully for the next 3 weeks.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating tasks: $e")),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _fallbackTasks(List<DateTime> dates) {
    List<Map<String, dynamic>> tasks = [];
    List<String> fallbackTitles = [
      "Soil Preparation",
      "Plant Seeds",
      "Inspect for Pests",
      "Apply Fertilizer",
      "Water Crops",
      "Prune Plants",
      "Check Soil pH",
      "Plan Crop Rotation",
      "Monitor Weather",
      "Harvest Early Crops",
      "Weed Fields",
      "Install Drip Irrigation",
      "Test Soil Nutrients",
      "Scout for Diseases",
      "Mulch Beds",
      "Prepare Compost",
      "Check Equipment",
      "Sow Cover Crops",
      "Monitor Growth",
      "Apply Pest Control",
      "Review Harvest Plan",
    ];
    List<String> fallbackDescriptions = [
      "Till the soil to prepare for planting.",
      "Sow seeds for the next crop cycle.",
      "Look for signs of pests and take action.",
      "Add organic fertilizer to boost soil health.",
      "Water crops lightly to maintain moisture.",
      "Trim overgrown plants to encourage growth.",
      "Test soil pH and adjust if necessary.",
      "Plan next season’s crop rotation.",
      "Monitor weather forecasts for the week.",
      "Harvest early-maturing crops today.",
      "Remove weeds to prevent competition.",
      "Set up drip irrigation for efficient watering.",
      "Test soil for nutrient deficiencies.",
      "Scout fields for early signs of disease.",
      "Add mulch to retain soil moisture.",
      "Start a new compost pile for future use.",
      "Inspect and maintain farming equipment.",
      "Sow cover crops to improve soil health.",
      "Check crop growth and adjust care.",
      "Apply organic pest control methods.",
      "Review and adjust your harvest schedule.",
    ];
    for (int i = 0; i < dates.length; i++) {
      tasks.add({
        "date": dates[i].toIso8601String().split('T')[0],
        "title": fallbackTitles[i % fallbackTitles.length],
        "description": fallbackDescriptions[i % fallbackDescriptions.length],
      });
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    DateTime firstDay = DateTime.now().subtract(const Duration(days: 365));
    DateTime lastDay = DateTime.now().add(const Duration(days: 365));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Calendar', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color.fromARGB(255, 66, 192, 201)),
            onPressed: _isLoading ? null : _generateTasksForNextThreeWeeks,
            tooltip: "Generate Tasks for Next 3 Weeks",
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color.fromARGB(255, 66, 192, 201)),
            onPressed: () {
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
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color.fromARGB(255, 66, 192, 201),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color.fromARGB(255, 66, 192, 201),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.black),
              outsideTextStyle: TextStyle(color: Colors.grey),
            ),
            headerStyle: const HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Color.fromARGB(255, 66, 192, 201)),
              rightChevronIcon: Icon(Icons.chevron_right, color: Color.fromARGB(255, 66, 192, 201)),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
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

class AddEventPage extends StatelessWidget {
  const AddEventPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: const Center(
        child: Text("Manual event addition page", style: TextStyle(color: Colors.black)),
      ),
    );
  }
}