import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as googleCalendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:agrisync/App%20Pages/Calendar/AddEventPage.dart';
import 'package:agrisync/App%20Pages/Calendar/EventDetailsPage.dart';

// Handy class to hold event info
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  String? googleCalendarEventId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.googleCalendarEventId,
  });

  // Turns Firestore doc into an event
  factory CalendarEvent.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      googleCalendarEventId: data['googleCalendarEventId'],
    );
  }

  // Preps event data for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
      'googleCalendarEventId': googleCalendarEventId,
    };
  }
}

class FarmCalendarPage extends StatefulWidget {
  final String? userCity;
  final Map<String, dynamic>? currentWeather;
  const FarmCalendarPage({Key? key, this.userCity, this.currentWeather}) : super(key: key);

  @override
  _FarmCalendarPageState createState() => _FarmCalendarPageState();
}

class _FarmCalendarPageState extends State<FarmCalendarPage> {
  late final FirebaseAuth _auth; // Auth hookup
  late final FirebaseFirestore _firestore; // Firestore hookup
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      googleCalendar.CalendarApi.calendarScope,
    ],
  );
  googleCalendar.CalendarApi? _calendarApi;
  bool _isGoogleSignedIn = false;
  
  CalendarFormat _calendarFormat = CalendarFormat.month; // Default to month view
  late DateTime _focusedDay; // What day we're zoomed in on
  DateTime? _selectedDay; // What day we clicked
  Map<DateTime, List<CalendarEvent>> _events = {}; // Events mapped by date
  bool _isLoading = false; // Shows if we're generating tasks
  bool _isSyncing = false; // Shows if we're syncing with Google Calendar

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadEvents(); // Kick off event loading
    _checkGoogleSignIn(); // Check Google sign-in status
  }

  // Check if user is already signed in with Google
  Future<void> _checkGoogleSignIn() async {
    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      if (isSignedIn) {
        await _handleGoogleSignIn();
      }
    } catch (e) {
      print("Error checking Google sign-in: $e");
    }
  }

  // Handle Google Sign In
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isSyncing = true;
      });
      
      // Force fresh authentication to ensure we get valid tokens
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() {
          _isSyncing = false;
        });
        return;
      }
      
      // Get the auth client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient != null) {
        _calendarApi = googleCalendar.CalendarApi(httpClient);
        setState(() {
          _isGoogleSignedIn = true;
          _isSyncing = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully connected to Google Calendar"))
        );
      } else {
        setState(() {
          _isSyncing = false;
        });
      }
    } catch (e) {
      print("Error signing in with Google: $e");
      setState(() {
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to Google Calendar: $e"))
      );
    }
  }

  // Sign out from Google
  Future<void> _handleGoogleSignOut() async {
    try {
      await _googleSignIn.signOut();
      setState(() {
        _isGoogleSignedIn = false;
        _calendarApi = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Disconnected from Google Calendar"))
      );
    } catch (e) {
      print("Error signing out from Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to disconnect from Google Calendar: $e"))
      );
    }
  }

  // Creates a Google Calendar event and returns the ID
  Future<String?> _createGoogleCalendarEvent(CalendarEvent event) async {
    if (_calendarApi == null) return null;
    
    try {
      // Create Google Calendar event
      final googleEvent = googleCalendar.Event();
      googleEvent.summary = event.title;
      googleEvent.description = event.description;
      
      // Set start time with timezone
      final startDateTime = googleCalendar.EventDateTime();
      startDateTime.dateTime = event.date.toUtc();
      startDateTime.timeZone = 'UTC';
      googleEvent.start = startDateTime;
      
      // Set end time (1 hour later) with timezone
      final endDateTime = googleCalendar.EventDateTime();
      endDateTime.dateTime = event.date.toUtc().add(const Duration(hours: 1));
      endDateTime.timeZone = 'UTC';
      googleEvent.end = endDateTime;
      
      // Insert the event
      final createdEvent = await _calendarApi!.events.insert(googleEvent, 'primary');
      return createdEvent.id;
    } catch (e) {
      print("Error creating Google Calendar event: $e");
      return null;
    }
  }

  // Sync all events to Google Calendar
  Future<void> _syncEventsToGoogleCalendar() async {
    if (_calendarApi == null) {
      await _handleGoogleSignIn();
      if (_calendarApi == null) return;
    }
    
    try {
      setState(() {
        _isSyncing = true;
      });
      
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Get all events from Firestore
      final querySnapshot = await _firestore
          .collection('farmActivities')
          .doc(user.uid)
          .collection('events')
          .get();
      
      int syncedCount = 0;
      
      for (var doc in querySnapshot.docs) {
        final event = CalendarEvent.fromDocument(doc);
        
        // Skip if already synced
        if (event.googleCalendarEventId != null) continue;
        
        // Create Google Calendar event
        final eventId = await _createGoogleCalendarEvent(event);
        if (eventId == null) continue;
        
        // Update Firestore with Google Calendar event ID
        await _firestore
            .collection('farmActivities')
            .doc(user.uid)
            .collection('events')
            .doc(event.id)
            .update({'googleCalendarEventId': eventId});
            
        syncedCount++;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(syncedCount > 0 
            ? "Successfully synced $syncedCount events to Google Calendar" 
            : "All events are already synced"))
      );
    } catch (e) {
      print("Error syncing events to Google Calendar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to sync events: $e"))
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  // Pulls events from Firestore and keeps them updated
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
        final dayKey = DateTime(event.date.year, event.date.month, event.date.day);
        eventsMap.putIfAbsent(dayKey, () => []).add(event);
      }
      setState(() {
        _events = eventsMap;
      });
    });
  }

  // Gets events for a specific day
  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  // Fetches user data from Firestore
  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    if (snapshot.exists) {
      return snapshot.data()!;
    }
    return {};
  }

  // Clears out future events before generating new ones
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
      // Delete from Google Calendar if connected
      final event = CalendarEvent.fromDocument(doc);
      if (_calendarApi != null && event.googleCalendarEventId != null) {
        try {
          await _calendarApi!.events.delete('primary', event.googleCalendarEventId!);
        } catch (e) {
          print("Error deleting event from Google Calendar: $e");
        }
      }
      // Delete from Firestore
      await doc.reference.delete();
    }
  }

  // Pulls JSON array from AI response text
  String extractJson(String text) {
    int start = text.indexOf('[');
    int end = text.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return '';
  }

  // Asks AI to make tasks for the next 3 weeks
  Future<void> _generateTasksForNextThreeWeeks() async {
    await _deleteFutureEvents();
    setState(() {
      _isLoading = true; // Show loading bar
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
      userDataInfo = "Farm Size: 10 acres, Preferred Crops: tomatoes, corn."; // Fallback if no data
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
        print("AI response: $aiText"); // Debugging peek
        String jsonString = extractJson(aiText);
        if (jsonString.isNotEmpty) {
          try {
            tasks = json.decode(jsonString);
          } catch (e) {
            print("Error parsing JSON: $e");
            tasks = _fallbackTasks(datesToGenerate); // Backup plan
          }
        } else {
          print("No valid JSON found in AI response");
          tasks = _fallbackTasks(datesToGenerate);
        }
      } else {
        print("API failed with status: ${response.statusCode}");
        tasks = _fallbackTasks(datesToGenerate);
      }

      int syncedCount = 0;
      for (var task in tasks) {
        DateTime taskDate = DateTime.parse(task["date"]);
        if (taskDate.isBefore(today)) continue;
        
        // Create the event with a placeholder ID
        CalendarEvent event = CalendarEvent(
          id: "",
          title: task["title"],
          description: task["description"],
          date: taskDate,
        );
        
        // First try to add to Google Calendar if connected
        String? googleCalendarEventId;
        if (_calendarApi != null) {
          try {
            googleCalendarEventId = await _createGoogleCalendarEvent(event);
            if (googleCalendarEventId != null) {
              syncedCount++;
            }
          } catch (e) {
            print("Error adding event to Google Calendar: $e");
          }
        }
        
        // Prepare the event data with Google Calendar ID if available
        Map<String, dynamic> eventData = event.toMap();
        if (googleCalendarEventId != null) {
          eventData['googleCalendarEventId'] = googleCalendarEventId;
        }
        
        // Add to Firestore
        await _firestore
            .collection('farmActivities')
            .doc(user.uid)
            .collection('events')
            .add(eventData);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isGoogleSignedIn 
            ? "AI tasks generated and $syncedCount events synced to Google Calendar" 
            : "AI tasks generated successfully for the next 3 weeks"))
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

  // Backup tasks if AI fails
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
      "Plan next season's crop rotation.",
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
          // Google Calendar sync button
          _isSyncing 
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                width: 24,
                height: 24,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 66, 192, 201)),
                ),
              )
            : IconButton(
                icon: Icon(
                  _isGoogleSignedIn ? Icons.cloud_done : Icons.cloud_upload,
                  color: Color.fromARGB(255, 66, 192, 201),
                ),
                onPressed: _isGoogleSignedIn ? _syncEventsToGoogleCalendar : _handleGoogleSignIn,
                tooltip: _isGoogleSignedIn ? "Sync to Google Calendar" : "Connect Google Calendar",
              ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color.fromARGB(255, 66, 192, 201)),
            onPressed: _isLoading ? null : _generateTasksForNextThreeWeeks, // AI task generator
            tooltip: "Generate Tasks for Next 3 Weeks",
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color.fromARGB(255, 66, 192, 201)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEventPage(
                    googleSignIn: _isGoogleSignedIn ? _googleSignIn : null,
                    calendarApi: _calendarApi,
                  ),
                ),
              );
            },
            tooltip: "Add Event",
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          if (_isGoogleSignedIn)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Connected to Google Calendar", 
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _handleGoogleSignOut,
                    child: const Text("Disconnect", style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                ],
              ),
            ),
          if (_isLoading || _isSyncing) const LinearProgressIndicator(), // Loading bar when generating
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
                _focusedDay = focusedDay; // Update what we're looking at
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format; // Switch between week/month view
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
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _focusedDay).map((event) {
                return ListTile(
                  title: Text(event.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  subtitle: Text(event.description, style: const TextStyle(color: Colors.black)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (event.googleCalendarEventId != null)
                        Icon(Icons.cloud_done, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "${event.date.day}/${event.date.month}",
                        style: const TextStyle(color: Colors.grey), // Quick date peek
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsPage(
                          events: [event],
                          selectedDate: event.date,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}