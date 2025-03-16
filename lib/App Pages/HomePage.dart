import 'dart:convert';

import 'package:agrisync/App%20Pages/Pages/Weather/LocationService.dart';
import 'package:agrisync/App%20Pages/Pages/Weather/WeatherCard.dart';
import 'package:agrisync/Components/ToolTile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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
      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$userLat&lon=$userLon&appid=$weatherApiKey&units=metric';
      final currentResponse = await http.get(Uri.parse(currentUrl));

      if (currentResponse.statusCode == 200) {
        setState(() {
          currentWeather = json.decode(currentResponse.body);
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
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
                  'Provide a concise, actionable farming tip for a farmer in $_userCity, where the current weather is ${currentWeather!['weather'][0]['main']} with a temperature of ${currentWeather!['main']['temp']}°C. Ensure that there is no markdown text, and the tip is concise. Make the tip good based off the weather and other statistics given',
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

  // New method to build AI tip card
  Widget _buildAITipCard() {
    return GestureDetector(
      onTap: dailyTip.contains('Failed to fetch') ? _fetchAITip : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
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
          child: SingleChildScrollView(
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
                isTipLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        dailyTip,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
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
                          const Row(
                            children: [
                              Text(
                                "Welcome Back ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Color.fromARGB(255, 128, 128, 128)),
                    ),

                    // Notification icon
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
              const SizedBox(height: 10),
              const Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Updates",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 5.0),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios,
                              size: 18, color: Colors.grey),
                          SizedBox(width: 15),
                          Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Replace the PageView implementation with this:
              if (_isLoadingLocation)
                const Center(child: CircularProgressIndicator())
              else if (_userCity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    height: 220, // Adjust height as needed
                    child: PageView(
                      controller: _updatesPageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        // Weather Card
                        Center(
                          child: WeatherCard(
                            apiKey: 'eeaca43a04ac307588b75ac98f9871d7',
                            city: _userCity!,
                          ),
                        ),
                        // AI Tip Card - Only build if animation is initialized
                        if (_tipAnimationController.isAnimating ||
                            _tipAnimationController.status !=
                                AnimationStatus.dismissed)
                          _buildAITipCard()
                        else
                          Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              const Padding(
                padding: const EdgeInsets.only(left: 15, top: 15),
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
                            Icons.forum_outlined, // Using forum icon
                            size: 23,
                            color: Color.fromARGB(255, 66, 192, 201),
                          ),
                          onTap: () {
                            // Navigate to Forum page
                          },
                        ),
                        ToolTile(
                          title: "Inventory",
                          icon: const Icon(
                            Icons.inventory, // Using forum icon
                            size: 23,
                            color: Color.fromARGB(255, 66, 192, 201),
                          ),
                          onTap: () {
                            // Navigate to Forum page
                          },
                        ),
                        ToolTile(
                          title: "Tasks",
                          icon: const Icon(
                            Icons.calendar_today, // Using forum icon
                            size: 23,
                            color: Color.fromARGB(255, 66, 192, 201),
                          ),
                          onTap: () {
                            // Navigate to Forum page
                          },
                        ),
                        ToolTile(
                          title: "Crop Health",
                          icon: const Icon(
                            Icons.health_and_safety, // Using forum icon
                            size: 23,
                            color: Color.fromARGB(255, 66, 192, 201),
                          ),
                          onTap: () {
                            // Navigate to Forum page
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text("Recent Activity",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
