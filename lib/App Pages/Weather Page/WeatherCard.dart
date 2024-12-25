import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class WeatherCard extends StatefulWidget {
  final String apiKey;
  final String city;

  const WeatherCard({
    super.key, 
    required this.apiKey,
    required this.city,
  });

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

Future<void> fetchWeatherData() async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?q=${widget.city}&appid=${widget.apiKey}&units=metric';
      print('Fetching from URL: $url'); // Debug print

      final response = await http.get(Uri.parse(url));
      
      print('Response status: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch weather data (${response.statusCode}): ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error details: $e'); // Debug print
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String _getWeatherAdvice() {
    if (weatherData == null) return '';
    
    final temp = weatherData!['main']['temp'];
    final humidity = weatherData!['main']['humidity'];
    final clouds = weatherData!['clouds']['all'];
    
    if (temp > 20 && humidity < 85 && clouds < 70) {
      return 'Today is a good day to apply pesticides.';
    }
    return 'Not recommended for pesticide application.';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.city}, ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  weatherData!['clouds']['all'] > 50 
                    ? Icons.cloud 
                    : Icons.wb_sunny,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${weatherData!['main']['temp'].round()}°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Humidity ${weatherData!['main']['humidity']}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              weatherData!['weather'][0]['main'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getWeatherAdvice(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}