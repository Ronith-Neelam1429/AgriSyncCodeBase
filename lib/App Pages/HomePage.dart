import 'package:flutter/material.dart';
import 'package:agrisync/App%20Pages/Pages/Weather/WeatherPage.dart';
import 'package:agrisync/App%20Pages/Pages/Weather/LocationService.dart';
import 'package:agrisync/App%20Pages/Pages/Forum/forum_page.dart';
import 'package:agrisync/Components/TaskScheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _tipAnimationController;
  late Animation<double> _tipFadeAnimation;

  // Weather and Location Data
  Map<String, dynamic>? currentWeather;
  bool isWeatherLoading = true;
  String? userCity;
  String? userLat;
  String? userLon;
  final String weatherApiKey = 'eeaca43a04ac307588b75ac98f9871d7'; 

  // AI Farming Tip
  String dailyTip = 'Loading tip...';
  bool isTipLoading = true;
  List<String> savedTips = [];
  final String aiApiKey = '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'; // OpenRouter API for Llama

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _tipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _tipFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tipAnimationController, curve: Curves.easeInOut),
    );

    // Start animations
    _animationController.forward();
    _tipAnimationController.forward();

    // Initialize location and data
    _initializeLocationAndData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tipAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationAndData() async {
    try {
      final locationData = await LocationService.getCurrentLocation();
      if (locationData != null) {
        setState(() {
          userCity = locationData['city'];
          userLat = locationData['latitude'];
          userLon = locationData['longitude'];
        });
      } else {
        setState(() {
          userCity = 'Spokane'; // Backup location in case fetching fails
          userLat = '47.6580';
          userLon = '117.4235';
        });
      }
      await _fetchWeatherData();
      await _fetchAITip();
    } catch (e) {
      print('Error initializing location and data: $e');
      setState(() {
        isWeatherLoading = false;
        isTipLoading = false;
        dailyTip = 'Failed to initialize data. Please check your connection.';
      });
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
          isWeatherLoading = false;
        });
      } else {
        setState(() {
          isWeatherLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        isWeatherLoading = false;
      });
    }
  }

  Future<void> _fetchAITip() async {
    if (userCity == null || currentWeather == null) {
      setState(() {
        isTipLoading = false;
        dailyTip = 'Unable to fetch tip due to missing location or weather data.';
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
          'HTTP-Referer': 'https://agrisync-app.com', // Replace with site URL if we plan to make one
          'X-Title': 'AgriSync', 
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-3.2-3b-instruct:free',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Provide a concise, actionable farming tip for a farmer in $userCity, where the current weather is ${currentWeather!['weather'][0]['main']} with a temperature of ${currentWeather!['main']['temp']}°C. Ensure that there is no markdown text, and the tip is concise. Make the tip good based off the weather and other statistics given',
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

  void _saveTip(String tip) {
    if (tip.contains('Failed to fetch') || tip.contains('Unable to fetch')) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 27, 94, 32),
                          Color.fromARGB(255, 87, 189, 179),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Welcome to\n',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    TextSpan(
                                      text: 'Agri',
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: Color.fromARGB(255, 73, 167, 87),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Sync',
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: Color.fromARGB(255, 72, 219, 214),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userCity != null
                                    ? 'Manage your farm in $userCity'
                                    : 'Manage your farm',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.local_florist,
                          size: 50,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Farm Health Snapshot (Placeholder)
                  const Text(
                    'Farm Health Snapshot',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 87, 189, 179),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 39, 39, 39),
                          Color.fromARGB(255, 50, 50, 50),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Farm Health Snapshot feature coming soon!',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Weather Widget
                  const Text(
                    'Current Weather',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 87, 189, 179),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WeatherPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 39, 39, 39),
                            Color.fromARGB(255, 50, 50, 50),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isWeatherLoading
                          ? const Center(child: CircularProgressIndicator())
                          : currentWeather == null
                              ? const Center(
                                  child: Text(
                                    'Failed to load weather data.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          currentWeather!['weather'][0]['main']
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('rain')
                                              ? Icons.water_drop
                                              : currentWeather!['weather'][0]['main']
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains('cloud')
                                                  ? Icons.cloud
                                                  : Icons.wb_sunny,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${currentWeather!['main']['temp'].round()}°C',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              currentWeather!['weather'][0]['main'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Farming Tip of the Day
                  const Text(
                    'Farming Tip of the Day',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 87, 189, 179),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: dailyTip.contains('Failed to fetch') ? _fetchAITip : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                                  'AI Suggestion',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showSavedTips,
                                  child: const Text(
                                    'View Saved Tips',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            isTipLoading
                                ? const Center(child: CircularProgressIndicator())
                                : Text(
                                    dailyTip,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: isTipLoading ? null : () => _saveTip(dailyTip),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Save Tip',
                                  style: TextStyle(color: Color.fromARGB(255, 87, 189, 179)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Quick Actions Section
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 87, 189, 179),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildQuickAction(
                      icon: Icons.local_florist,
                      label: 'Crop Health',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Crop Health feature coming soon!')),
                        );
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.forum,
                      label: 'Forum',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ForumPage()),
                        );
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.calendar_today,
                      label: 'Tasks',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TaskScheduler()),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats Overview Section
                const Text(
                  'Farm Stats',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 87, 189, 179),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStatCard('Total Crops', '3', Icons.local_florist),
                      const SizedBox(width: 16),
                      _buildStatCard('Farm Size', '250 acres', Icons.landscape),
                      const SizedBox(width: 16),
                      _buildStatCard('Tasks Due', '2', Icons.calendar_today),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Activity Section
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 87, 189, 179),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: const Color.fromARGB(255, 39, 39, 39),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildActivityRow(
                            'Completed Task: Water Crops', '10 mins ago'),
                        const Divider(color: Colors.grey),
                        _buildActivityRow(
                            'Added Note: Crop Observation', '1 hour ago'),
                        const Divider(color: Colors.grey),
                        _buildActivityRow('Checked Weather', '2 hours ago'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildQuickAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 39, 39, 39),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 35,
              color: const Color.fromARGB(255, 87, 189, 179),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 39, 39, 39),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: const Color.fromARGB(255, 87, 189, 179),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String activity, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            activity,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
