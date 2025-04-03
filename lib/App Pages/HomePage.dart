import 'dart:convert';

import 'package:agrisync/App%20Pages/Analytics/PlantDetector.dart';
import 'package:agrisync/App%20Pages/Forum/forum_page.dart';
import 'package:agrisync/App%20Pages/Calendar/FarmCalendarPage.dart';
import 'package:agrisync/App%20Pages/Inventory/InventoryPage.dart';
import 'package:agrisync/App%20Pages/Weather/LocationService.dart';
import 'package:agrisync/App%20Pages/Weather/WeatherCard.dart';
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
  String userName = ""; // Holds the user’s name
  String? _userCity;
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>>? forecast;

  late AnimationController _tipAnimationController;
  late Animation<double> _tipFadeAnimation;
  String dailyTip = 'Loading tip...'; // Daily AI tip text
  bool isTipLoading = true;
  List<String> savedTips = []; // Store saved tips
  final String aiApiKey =
      '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'; // OpenRouter API key

  Map<String, dynamic>? currentWeather;
  String? userLat;
  String? userLon;
  final String weatherApiKey = 'eeaca43a04ac307588b75ac98f9871d7'; // Weather API key

  final PageController _updatesPageController = PageController(); // For today’s updates carousel
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo(); // Grab user info on start
    _updateUserLocation(); // Get user’s location

    // Set up the tip fade animation
    _tipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _tipFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tipAnimationController, curve: Curves.easeInOut),
    );
    _tipAnimationController.forward(); // Start the animation
  }

  @override
  void dispose() {
    _tipAnimationController.dispose();
    _updatesPageController.dispose();
    super.dispose(); // Clean up controllers
  }

  // Pulls user’s name from Firestore
  Future<void> _fetchUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists && userData.data() != null) {
        final data = userData.data()!;
        final possibleNames = [
          'name',
          'fullName',
          'displayName',
          'firstName',
          'username'
        ];
        String foundName = "User";

        for (String field in possibleNames) {
          if (data.containsKey(field) && data[field]?.isNotEmpty == true) {
            foundName = data[field].toString();
            break;
          }
        }

        setState(() {
          userName = foundName;
          isLoading = false;
        });
      } else {
        setState(() {
          userName = "User";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = "User";
        isLoading = false;
      });
    }
  }

  // Gets initials from the user’s name for the avatar
  String _getInitials(String name) {
    if (name.isEmpty) return "";
    final nameParts = name.split(" ");
    if (nameParts.length >= 2) {
      return "${nameParts[0][0]}${nameParts.last[0]}".toUpperCase();
    } else if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }
    return "";
  }

  // Fetches user’s location and sets defaults if needed
  Future<void> _updateUserLocation() async {
    try {
      final locationData = await LocationService.getCurrentLocation();
      if (locationData != null) {
        setState(() {
          _userCity = locationData['city'];
          userLat = locationData['latitude'];
          userLon = locationData['longitude'];
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _userCity = 'Bothell'; // Default to Bothell if no location
          userLat = '47.7601';
          userLon = '122.2054';
          _isLoadingLocation = false;
        });
      }
      await _fetchWeatherData();
      await _fetchAITip();
    } catch (e) {
      setState(() {
        _userCity = 'Bothell';
        userLat = '47.7601';
        userLon = '122.2054';
        _isLoadingLocation = false;
      });
      await _fetchWeatherData();
      await _fetchAITip();
    }
  }

  // Grabs current weather and forecast data
  Future<void> _fetchWeatherData() async {
    if (userLat == null || userLon == null) return;
    try {
      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$userLat&lon=$userLon&appid=$weatherApiKey&units=metric';
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$userLat&lon=$userLon&appid=$weatherApiKey&units=metric';
      
      final currentResponse = await http.get(Uri.parse(currentUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        setState(() {
          currentWeather = json.decode(currentResponse.body);
          forecast = _processForecastData(json.decode(forecastResponse.body)['list']);
        });
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  // Processes forecast data into daily chunks
  List<Map<String, dynamic>> _processForecastData(List<dynamic> forecastList) {
    Map<String, dynamic> dailyForecasts = {};
    DateTime now = DateTime.now();

    for (var forecast in forecastList) {
      DateTime forecastDate = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      String date = DateFormat('yyyy-MM-dd').format(forecastDate);

      if (forecastDate.difference(now).inDays == 0) continue; // Skip today

      if (!dailyForecasts.containsKey(date)) {
        dailyForecasts[date] = forecast;
      }
    }
    return dailyForecasts.values.take(4).toList().cast<Map<String, dynamic>>();
  }

  // Fetches an AI-generated farming tip
  Future<void> _fetchAITip() async {
    if (_userCity == null || currentWeather == null) {
      setState(() {
        isTipLoading = false;
        dailyTip = 'Unable to fetch tip due to missing data.';
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
          dailyTip = 'Failed to fetch tip. Tap to retry.';
          isTipLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        dailyTip = 'Failed to fetch tip. Tap to retry.';
        isTipLoading = false;
      });
    }
  }

  // Saves a tip to the list
  void _saveTip(String tip) {
    if (tip.contains('Failed') || tip.contains('Unable')) return;
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

  // Shows saved tips in a dialog
  void _showSavedTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 39, 39, 39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Saved Tips', style: TextStyle(color: Colors.white)),
        content: savedTips.isEmpty
            ? const Text('No saved tips yet.', style: TextStyle(color: Colors.grey))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: savedTips.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('- ${savedTips[index]}', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color.fromARGB(255, 87, 189, 179))),
          ),
        ],
      ),
    );
  }

  // Builds the weekly schedule carousel
  Widget _buildWeeklySchedule() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUpcomingEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading schedule');
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final events = snapshot.data!.docs
            .map((doc) => CalendarEvent.fromDocument(doc))
            .toList();

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

  // Generates week containers for the schedule
  List<Widget> _generateWeekContainers(List<CalendarEvent> events) {
    final weeks = <Widget>[];
    DateTime currentDate = DateTime.now();

    for (int i = 0; i < 4; i++) {
      final weekStart = currentDate.subtract(Duration(days: currentDate.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekEvents = events
          .where((event) => event.date.isAfter(weekStart) && event.date.isBefore(weekEnd))
          .toList();

      weeks.add(_buildWeekContainer(weekStart, weekEnd, weekEvents));
      currentDate = weekEnd.add(const Duration(days: 1));
    }
    return weeks;
  }

  // Builds a single week container
  Widget _buildWeekContainer(DateTime startDate, DateTime endDate, List<CalendarEvent> events) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color.fromARGB(255, 87, 189, 179)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 12)],
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
                  '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3AAFA9)),
                ),
                Icon(Icons.calendar_view_week, color: Colors.grey.shade400),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: events.isEmpty
                  ? const Center(child: Text("No tasks this week", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: 7,
                      separatorBuilder: (context, index) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final day = startDate.add(Duration(days: index));
                        final dayEvents = events.where((e) => isSameDay(e.date, day)).toList();
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                DateFormat('EEE').format(day),
                                style: TextStyle(
                                  color: isSameDay(day, DateTime.now()) ? const Color(0xFF3AAFA9) : Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: dayEvents.isEmpty
                                  ? Text("No tasks", style: TextStyle(color: Colors.grey.shade400))
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: dayEvents
                                          .map((event) => Padding(
                                                padding: const EdgeInsets.only(bottom: 4),
                                                child: Text('• ${event.title}', style: const TextStyle(fontSize: 14)),
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

  // Fetches upcoming events from Firestore
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
        .orderBy('date')
        .snapshots();
  }

  // Builds the AI tip card
  Widget _buildAITipCard() {
    return GestureDetector(
      onTap: dailyTip.contains('Failed') ? _fetchAITip : null,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 70, 197, 161), Color.fromARGB(255, 87, 189, 179)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
        ),
        child: FadeTransition(
          opacity: _tipFadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Farming Tip', style: TextStyle(fontSize: 17, color: Colors.white)),
                  GestureDetector(
                    onTap: _showSavedTips,
                    child: const Text('View Saved', style: TextStyle(fontSize: 14, color: Colors.black)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Stack(
                  children: [
                    isTipLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dailyTip, style: const TextStyle(fontSize: 16, color: Colors.white)),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('Save Tip', style: TextStyle(color: Color.fromARGB(255, 87, 189, 179))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the weather card
  Widget _buildWeatherCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: WeatherCard(apiKey: weatherApiKey, city: _userCity!),
    );
  }

  // Builds a forecast card for each day
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
          colors: [Color.fromARGB(255, 120, 187, 208), Color.fromARGB(255, 87, 189, 179)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(DateFormat('EEE').format(date), style: const TextStyle(color: Colors.white)),
          Icon(
            weatherMain.contains('rain') ? Icons.water_drop : weatherMain.contains('cloud') ? Icons.cloud : Icons.wb_sunny,
            color: Colors.white,
            size: 30,
          ),
          Text('${(temp * 1.8 + 32).round()}°F', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // Shows weather stats in a popup
  void _showWeatherStatsPopup() {
    if (currentWeather == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weather Details'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildStatItem('Wind Speed', '${currentWeather!['wind']['speed']} m/s'),
              _buildStatItem('Wind Direction', '${currentWeather!['wind']['deg']}°'),
              _buildStatItem('Humidity', '${currentWeather!['main']['humidity']}%'),
              _buildStatItem('Pressure', '${currentWeather!['main']['pressure']} hPa'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? _getInitials(userName) : "?",
                          style: const TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: const [
                            Text("Welcome Back ", style: TextStyle(fontSize: 16, color: Colors.grey)),
                            SizedBox(width: 4),
                            Text("👋", style: TextStyle(fontSize: 16)),
                          ]),
                          Text(
                            isLoading ? "Loading..." : userName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.settings, color: Color.fromARGB(255, 128, 128, 128)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's Updates", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.grey),
                          onPressed: () => _updatesPageController.previousPage(
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                          onPressed: () => _updatesPageController.nextPage(
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isLoadingLocation)
                const Center(child: CircularProgressIndicator())
              else if (_userCity != null)
                Container(
                  height: 200,
                  child: PageView(
                    controller: _updatesPageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [_buildWeatherCard(), _buildAITipCard()],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(left: 15, top: 15),
                child: Text("Tools for you", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 8.0),
                  children: [
                    ToolTile(
                      title: "Forum",
                      icon: const Icon(Icons.forum_outlined, size: 23, color: Color.fromARGB(255, 66, 192, 201)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ForumPage())),
                    ),
                    ToolTile(
                      title: "Inventory",
                      icon: const Icon(Icons.inventory, size: 23, color: Color.fromARGB(255, 66, 192, 201)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryPage())),
                    ),
                    ToolTile(
                      title: "Crop Health",
                      icon: const Icon(Icons.health_and_safety, size: 23, color: Color.fromARGB(255, 66, 192, 201)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlantMaturityDetectorPage())),
                    ),
                    ToolTile(
                      title: "Calendar",
                      icon: const Icon(Icons.calendar_today, size: 23, color: Color.fromARGB(255, 66, 192, 201)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FarmCalendarPage())),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("4 Day Forecast", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 22),
                      onPressed: _showWeatherStatsPopup,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              if (forecast != null)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 8),
                    itemCount: forecast!.length,
                    itemBuilder: (context, index) => _buildForecastCard(forecast![index]),
                  ),
                ),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: Text("Weekly Schedule", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              _buildWeeklySchedule(),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder class for CalendarEvent (since it’s not provided)
class CalendarEvent {
  final DateTime date;
  final String title;

  CalendarEvent(this.date, this.title);

  static CalendarEvent fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      (data['date'] as Timestamp).toDate(),
      data['title'] ?? 'Untitled',
    );
  }
}