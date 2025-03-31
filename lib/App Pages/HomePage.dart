import 'dart:convert';

import 'package:agrisync/App%20Pages/Forum/forum_page.dart';
import 'package:agrisync/App%20Pages/Calendar/FarmCalendarPage.dart';
import 'package:agrisync/App%20Pages/Inventory/InventoryPage.dart';
import 'package:agrisync/App%20Pages/Weather/LocationService.dart';
import 'package:agrisync/App%20Pages/Weather/WeatherCard.dart';
import 'package:agrisync/Components/TaskScheduler.dart';
import 'package:agrisync/Components/ToolTile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isLoading = true;
  String userName = ""; // Added state variable to store user's name
  String? _userCity;
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>>? forecast;

  late AnimationController _tipAnimationController;
  late Animation<double> _tipFadeAnimation;
  String dailyTip = 'Loading tip...';
  bool isTipLoading = true;
  List<String> savedTips = [];
  final String aiApiKey =
      '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'; // OpenRouter API for Llama

  Map<String, dynamic>? currentWeather;
  String? userLat;
  String? userLon;
  final String weatherApiKey = 'eeaca43a04ac307588b75ac98f9871d7';

  // Today's Updates carousel controller
  final PageController _updatesPageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo(); // Fetch user info when widget initializes
    _updateUserLocation();

    // Initialize tip animation controller
    _tipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _tipFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tipAnimationController, curve: Curves.easeInOut),
    );

    // Start animation
    _tipAnimationController.forward();
  }

  @override
  void dispose() {
    _tipAnimationController.dispose();
    _updatesPageController.dispose();
    super.dispose();
  }

  // Fetch user info
  Future<void> _fetchUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user is signed in');
        setState(() {
          isLoading = false;
        });
        return;
      }

      print('Fetching data for user ID: ${user.uid}');

      // Fetch user data from Firestore
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Print the entire document for debugging
      print('User document exists: ${userData.exists}');
      if (userData.exists) {
        print('User data: ${userData.data()}');
      }

      // Extract the user's name from Firestore document
      if (userData.exists && userData.data() != null) {
        final data = userData.data()!;

        // Try different possible field names
        final possibleNames = [
          'name',
          'fullName',
          'displayName',
          'firstName',
          'username'
        ];
        String foundName = "User";

        for (String field in possibleNames) {
          if (data.containsKey(field) &&
              data[field] != null &&
              data[field].toString().isNotEmpty) {
            foundName = data[field].toString();
            print('Found name in field: $field = $foundName');
            break;
          }
        }

        setState(() {
          userName = foundName;
          isLoading = false;
        });
      } else {
        print('User document does not exist or is empty');
        setState(() {
          userName = "User";
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userName = "User";
        isLoading = false;
      });
    }
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return "";

    final nameParts = name.split(" ");
    if (nameParts.length >= 2) {
      // Get first letter of first and last name
      return "${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}"
          .toUpperCase();
    } else if (nameParts.length == 1) {
      // Just get first letter if only one name
      return nameParts[0][0].toUpperCase();
    }

    return "";
  }

  // Function for fetching user location
  Future<void> _updateUserLocation() async {
    print('Updating user location...');
    try {
      final locationData = await LocationService.getCurrentLocation();

      if (locationData != null) {
        print('Location data received: ${locationData['city']}');
        setState(() {
          _userCity = locationData['city'];
          userLat = locationData['latitude'];
          userLon = locationData['longitude'];
          _isLoadingLocation = false;
        });

        // Fetch weather data and AI tip after location is known
        await _fetchWeatherData();
        await _fetchAITip();
      } else {
        print('No location data received, using default city');
        setState(() {
          _userCity = 'London'; // Default city
          userLat = '51.5074'; // Default coordinates for London
          userLon = '0.1278';
          _isLoadingLocation = false;
        });

        // Use default location for weather and tip
        await _fetchWeatherData();
        await _fetchAITip();
      }
    } catch (e) {
      print('Error updating location: $e');
      setState(() {
        _userCity = 'London'; // Default city
        userLat = '51.5074'; // Default coordinates for London
        userLon = '0.1278';
        _isLoadingLocation = false;
      });

      // Try with default location
      await _fetchWeatherData();
      await _fetchAITip();
    }
  }

  Future<void> _fetchWeatherData() async {
    if (userLat == null || userLon == null) return;
    try {
      // Fetch current weather
      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$userLat&lon=$userLon&appid=$weatherApiKey&units=metric';
      final currentResponse = await http.get(Uri.parse(currentUrl));

      // Fetch forecast
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$userLat&lon=$userLon&appid=$weatherApiKey&units=metric';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (currentResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          currentWeather = json.decode(currentResponse.body);
          var forecastData = json.decode(forecastResponse.body);
          forecast = _processForecastData(forecastData['list']);
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  List<Map<String, dynamic>> _processForecastData(List<dynamic> forecastList) {
    Map<String, dynamic> dailyForecasts = {};
    DateTime now = DateTime.now();

    for (var forecast in forecastList) {
      DateTime forecastDate =
          DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      String date = DateFormat('yyyy-MM-dd').format(forecastDate);

      if (forecastDate.difference(now).inDays == 0) continue;

      if (!dailyForecasts.containsKey(date)) {
        dailyForecasts[date] = forecast;
      }
    }

    return dailyForecasts.values.take(4).toList().cast<Map<String, dynamic>>();
  }

  // New method to fetch AI farming tip
  Future<void> _fetchAITip() async {
    if (_userCity == null || currentWeather == null) {
      setState(() {
        isTipLoading = false;
        dailyTip =
            'Unable to fetch tip due to missing location or weather data.';
      });
      return;
    }

    setState(() => isTipLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $aiApiKey',
          'HTTP-Referer': 'https://agrisync-app.com',
          'X-Title': 'AgriSync',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-3.2-3b-instruct:free',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Provide a concise, actionable farming tip for a farmer in $_userCity, where the current weather is ${currentWeather!['weather'][0]['main']} with a temperature of ${currentWeather!['main']['temp']}°C. Ensure that there is no markdown text, and the tip is concise. Make the tip good based off the weather and other statistics given.',
            },
          ],
          'max_tokens': 100,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          dailyTip = data['choices'][0]['message']['content'].trim();
          isTipLoading = false;
          _tipAnimationController.reset();
          _tipAnimationController.forward();
        });
      } else {
        setState(() {
          dailyTip = 'Failed to fetch tip from AI. Tap to retry.';
          isTipLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching AI tip: $e');
      setState(() {
        dailyTip = 'Failed to fetch tip from AI. Tap to retry.';
        isTipLoading = false;
      });
    }
  }

  // New method to save tips
  void _saveTip(String tip) {
    if (tip.contains('Failed to fetch') || tip.contains('Unable to fetch'))
      return;
    setState(() {
      if (!savedTips.contains(tip)) {
        savedTips.add(tip);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip saved!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip already saved!')),
        );
      }
    });
  }

  // New method to show saved tips
  void _showSavedTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 39, 39, 39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Saved Tips',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: savedTips.isEmpty
            ? const Text(
                'No saved tips yet.',
                style: TextStyle(color: Colors.grey),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: savedTips.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '- ${savedTips[index]}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color.fromARGB(255, 87, 189, 179)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUpcomingEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading schedule');
        if (!snapshot.hasData) return const LinearProgressIndicator();

        // Get all events and group by week
        final events = snapshot.data!.docs
            .map((doc) => CalendarEvent.fromDocument(doc))
            .toList();

        // Create list of weeks starting from current week
        final weeks = _generateWeekContainers(events);

        return Container(
          height: 220,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: PageView.builder(
            itemCount: weeks.length,
            itemBuilder: (context, index) => weeks[index],
          ),
        );
      },
    );
  }

  List<Widget> _generateWeekContainers(List<CalendarEvent> events) {
    final weeks = <Widget>[];
    DateTime currentDate = DateTime.now();

    // Generate 4 weeks starting from current week
    for (int i = 0; i < 4; i++) {
      final weekStart =
          currentDate.subtract(Duration(days: currentDate.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weekEvents = events
          .where((event) =>
              event.date.isAfter(weekStart) && event.date.isBefore(weekEnd))
          .toList();

      weeks.add(_buildWeekContainer(weekStart, weekEnd, weekEvents));
      currentDate = weekEnd.add(const Duration(days: 1));
    }

    return weeks;
  }

  Widget _buildWeekContainer(
      DateTime startDate, DateTime endDate, List<CalendarEvent> events) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d').format(startDate) +
                      ' - ' +
                      DateFormat('MMM d').format(endDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3AAFA9),
                    fontSize: 16,
                  ),
                ),
                Icon(Icons.calendar_view_week, color: Colors.grey.shade400),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Text("No tasks this week",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: 7,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final day = startDate.add(Duration(days: index));
                        final dayEvents = events
                            .where((e) => isSameDay(e.date, day))
                            .toList();

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                DateFormat('EEE').format(day),
                                style: TextStyle(
                                  color: isSameDay(day, DateTime.now())
                                      ? const Color(0xFF3AAFA9)
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: dayEvents.isEmpty
                                  ? Text("No tasks",
                                      style: TextStyle(
                                          color: Colors.grey.shade400))
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: dayEvents
                                          .map((event) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4),
                                                child: Text(
                                                  '• ${event.title}',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Add to _HomePageState class in HomePage.dart
Stream<QuerySnapshot> _getUpcomingEvents() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = startDate.add(const Duration(days: 35));

  return FirebaseFirestore.instance
      .collection('farmActivities')
      .doc(user.uid)
      .collection('events')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .orderBy('date', descending: false)
      .snapshots();
}

  Widget _buildSchedule() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUpcomingEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading schedule');
        if (!snapshot.hasData) return const LinearProgressIndicator();

        // Group events by date
        Map<DateTime, List<CalendarEvent>> eventsMap = {};
        for (var doc in snapshot.data!.docs) {
          final event = CalendarEvent.fromDocument(doc);
          final day =
              DateTime(event.date.year, event.date.month, event.date.day);
          eventsMap.putIfAbsent(day, () => []).add(event);
        }

        // Get sorted list of dates
        final dates = eventsMap.keys.toList()..sort();

        return Container(
          height: 180,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final events = eventsMap[date]!;

              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE, MMM d').format(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 66, 192, 201),
                        ),
                      ),
                      Expanded(
                        child: events.isEmpty
                            ? const Center(
                                child: Text("No tasks",
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: events.length,
                                itemBuilder: (context, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.circle,
                                          size: 8,
                                          color: Color.fromARGB(
                                              255, 87, 189, 179)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          events[i].title,
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Updated method to build AI tip card with scrollable content and scroll indicator
  Widget _buildAITipCard() {
    return GestureDetector(
      onTap: dailyTip.contains('Failed to fetch') ? _fetchAITip : null,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 27, 94, 32),
              Color.fromARGB(255, 87, 189, 179),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FadeTransition(
          opacity: _tipFadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Farming Tip',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSavedTips,
                    child: const Text(
                      'View Saved',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Add a stack with content and scroll indicator
              Expanded(
                child: Stack(
                  children: [
                    // Scrollable content
                    isTipLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dailyTip,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                // Add space at bottom for better scrolling
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                    // Subtle scroll indicator
                    if (!isTipLoading)
                      Positioned(
                        right: 2,
                        top: 10,
                        bottom: 10,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Container(
                              height: 30,
                              width: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: isTipLoading ? null : () => _saveTip(dailyTip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: const Color.fromARGB(255, 87, 189, 179),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Save Tip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build Weather card with consistent sizing
  Widget _buildWeatherCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85, // Set a fixed width
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: WeatherCard(
        apiKey: 'eeaca43a04ac307588b75ac98f9871d7',
        city: _userCity!,
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> dayForecast) {
    final date = DateTime.fromMillisecondsSinceEpoch(dayForecast['dt'] * 1000);
    final temp = dayForecast['main']['temp'].toDouble();
    final weatherMain = dayForecast['weather'][0]['main'].toLowerCase();

    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 27, 94, 32),
            Color.fromARGB(255, 87, 189, 179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            DateFormat('EEE').format(date),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Icon(
            weatherMain.contains('rain')
                ? Icons.water_drop
                : weatherMain.contains('cloud')
                    ? Icons.cloud
                    : Icons.wb_sunny,
            color: Colors.white,
            size: 30,
          ),
          Text(
            '${(temp * 1.8 + 32).round()}°F',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showWeatherStatsPopup() {
    if (currentWeather == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weather Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildStatItem(
                  'Wind Speed', '${currentWeather!['wind']['speed']} m/s'),
              _buildStatItem(
                  'Wind Direction', '${currentWeather!['wind']['deg']}°'),
              _buildStatItem(
                  'Humidity', '${currentWeather!['main']['humidity']}%'),
              _buildStatItem(
                  'Pressure', '${currentWeather!['main']['pressure']} hPa'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Circle Avatar with initials
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? _getInitials(userName) : "?",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Welcome text and name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                "Welcome Back ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(
                                  width:
                                      4), // Add spacing between the text and emoji
                              Text(
                                "👋",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          // Updated to show actual user name
                          Text(
                            isLoading ? "Loading..." : userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Settings icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings,
                          color: Color.fromARGB(255, 128, 128, 128)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Updates",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    // Navigation arrows for the horizontal scroll
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              size: 18, color: Colors.grey),
                          onPressed: () {
                            _updatesPageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.grey),
                          onPressed: () {
                            _updatesPageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Horizontal ScrollView for Weather Card and AI Tip Card
              if (_isLoadingLocation)
                const Center(child: CircularProgressIndicator())
              else if (_userCity != null)
                Container(
                  height: 200, // Set a fixed height
                  child: PageView(
                    controller: _updatesPageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildWeatherCard(),
                      _buildAITipCard(),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(left: 15, top: 15),
                child: Text(
                  "Tools for you",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ToolTile(
                          title: "Forum",
                          icon: const Icon(
                            Icons.forum_outlined,
                            size: 23,
                            color: Color.fromARGB(255, 66, 192, 201),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForumPage(),
                              ),
                            );
                          },
                        ),
                        ToolTile(
                          title: "Inventory",
                          icon: const Icon(
                            Icons.inventory,
                            size: 23,
                            color: Color.fromARGB(255, 66, 192, 201),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InventoryPage(),
                              ),
                            );
                          },
                        ),
                        ToolTile(
                          title: "Crop Health",
                          icon: const Icon(
                            Icons.health_and_safety,
                            size: 23,
                            color: Color.fromARGB(255, 66, 192, 201),
                          ),
                          onTap: () {
                            // Navigate to Crop Health page
                          },
                        ),
                        ToolTile(
                          title: "Calendar",
                          icon: const Icon(
                            Icons.calendar_today,
                            size: 23,
                            color: Color.fromARGB(255, 66, 192, 201),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const FarmCalendarPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "4 Day Forecast",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 22),
                      onPressed: _showWeatherStatsPopup,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Add 4-day forecast
              if (forecast != null)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: forecast!.length,
                    padding: const EdgeInsets.only(left: 8),
                    itemBuilder: (context, index) =>
                        _buildForecastCard(forecast![index]),
                  ),
                ),
              SizedBox(height: 15),
              const Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  "Weekly Schedule",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildWeeklySchedule()
            ],
          ),
        ),
      ),
    );
  }
}
