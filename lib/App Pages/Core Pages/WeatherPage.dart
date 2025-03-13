import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // Added this import for Random
import 'package:intl/intl.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/Weather%20Components/LocationService.dart';
import 'package:flutter/animation.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final String apiKey = 'eeaca43a04ac307588b75ac98f9871d7';
  String selectedUnit = 'Celsius';
  Map<String, dynamic>? currentWeather;
  List<Map<String, dynamic>>? forecast;
  bool isLoading = true;
  String? userCity;
  String? userLat;
  String? userLon;

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
    _animationController.forward();
    _initializeLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final locationData = await LocationService.getCurrentLocation();
      if (locationData != null) {
        setState(() {
          userCity = locationData['city'];
          userLat = locationData['latitude'];
          userLon = locationData['longitude'];
        });
        await fetchWeatherData();
      } else {
        setState(() {
          userCity = 'London';
          userLat = '51.5074';
          userLon = '-0.1278';
        });
        await fetchWeatherData();
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        userCity = 'London';
        userLat = '51.5074';
        userLon = '-0.1278';
      });
      await fetchWeatherData();
    }
  }

  Future<void> fetchWeatherData() async {
    try {
      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$userLat&lon=$userLon&appid=$apiKey&units=metric';
      final currentResponse = await http.get(Uri.parse(currentUrl));

      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$userLat&lon=$userLon&appid=$apiKey&units=metric';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (currentResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          currentWeather = json.decode(currentResponse.body);
          var forecastData = json.decode(forecastResponse.body);
          forecast = _processForecastData(forecastData['list']);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        isLoading = false;
      });
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

  String _getWeatherAdvice(Map<String, dynamic> weather) {
    final temp = weather['main']['temp'];
    final humidity = weather['main']['humidity'];
    final clouds = weather['clouds']['all'];

    if (temp > 20 && humidity < 85 && clouds < 70) {
      return 'Today is a good day to apply pesticides.';
    }
    return 'Not recommended for pesticide application.';
  }

  String _getAdditionalAdvice(List<Map<String, dynamic>> forecastData) {
    bool hasRain = forecastData.any((day) =>
        day['weather'][0]['main'].toString().toLowerCase().contains('rain'));

    if (hasRain) {
      return 'Rainy weather is predicted to occur in the next few days. Thursday is a bad day to apply pesticides.';
    }
    return '';
  }

  Widget _buildUnitSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildUnitOption('Celsius'),
          _buildUnitOption('Fahrenheit'),
          _buildUnitOption('Kelvin'),
        ],
      ),
    );
  }

  Widget _buildUnitOption(String unit) {
    return GestureDetector(
      onTap: () => setState(() => selectedUnit = unit),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: unit,
              groupValue: selectedUnit,
              onChanged: (value) => setState(() => selectedUnit = value!),
            ),
            Text(unit),
          ],
        ),
      ),
    );
  }

  double _convertTemperature(double celsius) {
    switch (selectedUnit) {
      case 'Fahrenheit':
        return (celsius * 9 / 5) + 32;
      case 'Kelvin':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  String _getTemperatureUnit() {
    switch (selectedUnit) {
      case 'Fahrenheit':
        return '°F';
      case 'Kelvin':
        return 'K';
      default:
        return '°C';
    }
  }

  Color _getDynamicColor() {
    if (currentWeather == null) return const Color.fromARGB(255, 27, 94, 32);
    final weatherMain =
        currentWeather!['weather'][0]['main'].toString().toLowerCase();
    final temp = currentWeather!['main']['temp'];
    if (weatherMain.contains('rain')) return Colors.blue[700]!;
    if (weatherMain.contains('cloud') || temp < 15) return Colors.grey[700]!;
    if (temp > 25) return Colors.yellow[700]!;
    return const Color.fromARGB(255, 87, 189, 179);
  }

  Widget _buildCurrentWeather() {
    if (currentWeather == null) return const SizedBox();

    final temp =
        _convertTemperature(currentWeather!['main']['temp'].toDouble());
    final weatherMain = currentWeather!['weather'][0]['main'].toLowerCase();
    final advice = _getWeatherAdvice(currentWeather!);
    final additionalAdvice =
        forecast != null ? _getAdditionalAdvice(forecast!) : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getDynamicColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getDynamicColor().withOpacity(0.9),
            _getDynamicColor().withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$userCity, ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (weatherMain.contains('clear') || temp > 25)
                    const Icon(
                      Icons.wb_sunny,
                      color: Colors.yellow,
                      size: 30,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${temp.round()}${_getTemperatureUnit()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    weatherMain,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Humidity ${currentWeather!['main']['humidity']}%',
                style: const TextStyle(color: Colors.white70),
              ),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 10),
              Text(
                advice,
                style: const TextStyle(color: Colors.white),
              ),
              if (additionalAdvice.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      additionalAdvice,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
            ],
          ),
          if (weatherMain.contains('rain'))
            Positioned.fill(
              child: CustomPaint(
                painter: RainPainter(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> dayForecast) {
    final date = DateTime.fromMillisecondsSinceEpoch(dayForecast['dt'] * 1000);
    final temp = _convertTemperature(dayForecast['main']['temp'].toDouble());
    final weatherMain = dayForecast['weather'][0]['main'].toLowerCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 90,
      height: 150,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _getDynamicColor(),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('EEE').format(date),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
            '${temp.round()}${_getTemperatureUnit()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Hum ${dayForecast['main']['humidity']}%',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalWeatherStats() {
    if (currentWeather == null) return const SizedBox();

    final windSpeed = currentWeather!['wind']['speed'];
    final windDirection = currentWeather!['wind']['deg'];
    final pressure = currentWeather!['main']['pressure'];
    final visibility = currentWeather!['visibility'] / 1000;
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
      currentWeather!['sys']['sunrise'] * 1000,
    );
    final sunset = DateTime.fromMillisecondsSinceEpoch(
      currentWeather!['sys']['sunset'] * 1000,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Weather Stats',
          style: TextStyle(
            fontSize: 20,
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatCard('Wind Speed', '$windSpeed m/s'),
        _buildStatCard('Wind Direction', '$windDirection°'),
        _buildStatCard('Pressure', '$pressure hPa'),
        _buildStatCard('Visibility', '${visibility.toStringAsFixed(1)} km'),
        _buildStatCard('Sunrise', DateFormat('HH:mm').format(sunrise)),
        _buildStatCard('Sunset', DateFormat('HH:mm').format(sunset)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 39, 39, 39),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Weather',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: _buildUnitSelector(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCurrentWeather(),
              const SizedBox(height: 24),
              const Text(
                'Next 4 Days',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 16),
              if (forecast != null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: forecast!
                        .map((forecast) => _buildForecastCard(forecast))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 24),
              _buildAdditionalWeatherStats(),
            ],
          ),
        ),
      ),
    );
  }
}

class RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = Random(); // Now works with the dart:math import
    for (int i = 0; i < 20; i++) {
      double startX = random.nextDouble() * size.width;
      double startY = random.nextDouble() * size.height;
      double endY = startY + 10 + random.nextDouble() * 20;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, endY > size.height ? size.height : endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
