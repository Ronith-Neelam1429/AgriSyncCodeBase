import 'package:agrisync/App%20Pages/Weather%20Page/WeatherIcons.dart';
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
      final url =
          'https://api.openweathermap.org/data/2.5/weather?q=${widget.city}&appid=${widget.apiKey}&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch weather data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  bool _isNight() {
    if (weatherData == null) return false;

    // OpenWeatherMap icon codes end with 'd' for day and 'n' for night
    final iconCode = weatherData!['weather'][0]['icon'] as String;
    return iconCode.endsWith('n');
  }

  String _getWeatherType() {
    if (weatherData == null) return 'clear';

    final condition =
        weatherData!['weather'][0]['main'].toString().toLowerCase();
    final id = weatherData!['weather'][0]['id'];

    // OpenWeatherMap condition codes:
    // 2xx: Thunderstorm
    // 3xx: Drizzle
    // 5xx: Rain
    // 6xx: Snow
    // 7xx: Atmosphere (mist, smoke, etc.)
    // 800: Clear
    // 80x: Clouds

    if (id >= 200 && id < 300) {
      return 'stormy';
    } else if ((id >= 300 && id < 400) || (id >= 500 && id < 600)) {
      return 'rainy';
    } else if (id > 800) {
      return 'cloudy';
    } else {
      return 'clear';
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
      return const SizedBox(
        width: double.infinity,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
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
                      fontSize: 14,
                    ),
                  ),
                  WeatherIcon(
                    weatherType: _getWeatherType(),
                    isNight: _isNight(), // Add this line if missing
                    size: 48,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${weatherData!['main']['temp'].round()}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Humidity ${weatherData!['main']['humidity']}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weatherData!['weather'][0]['main'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white),
              Text(
                _getWeatherAdvice(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
