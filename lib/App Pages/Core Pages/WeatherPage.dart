import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:agrisync/App%20Pages/Core%20Pages/Weather%20Components/LocationService.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
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
    _initializeLocation();
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
        // Default to London if location service fails
        setState(() {
          userCity = 'London';
          userLat = '51.5074';
          userLon = '-0.1278';
        });
        await fetchWeatherData();
      }
    } catch (e) {
      print('Error getting location: $e');
      // Default to London if location service fails
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
      // Use coordinates for more accurate weather data
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
    // Get one forecast per day for the next 4 days
    Map<String, dynamic> dailyForecasts = {};
    DateTime now = DateTime.now();

    for (var forecast in forecastList) {
      DateTime forecastDate =
          DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      String date = DateFormat('yyyy-MM-dd').format(forecastDate);

      // Skip today's forecast
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
    // Check if any of the next few days have rain
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

  Widget _buildCurrentWeather() {
    if (currentWeather == null) return const SizedBox();

    final temp =
        _convertTemperature(currentWeather!['main']['temp'].toDouble());
    final advice = _getWeatherAdvice(currentWeather!);
    final additionalAdvice =
        forecast != null ? _getAdditionalAdvice(forecast!) : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[400],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$userCity, ${DateFormat('d MMM yyyy').format(DateTime.now())}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${temp.round()}${_getTemperatureUnit()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            'Humidity ${currentWeather!['main']['humidity']}%',
            style: const TextStyle(color: Colors.white),
          ),
          const Divider(color: Colors.white),
          Text(
            advice,
            style: const TextStyle(color: Colors.white),
          ),
          if (additionalAdvice.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              additionalAdvice,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> dayForecast) {
    final date = DateTime.fromMillisecondsSinceEpoch(dayForecast['dt'] * 1000);
    final temp = _convertTemperature(dayForecast['main']['temp'].toDouble());

    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.blue[300],
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
          Text(
            DateFormat('EEEE').format(date),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            dayForecast['weather'][0]['main']
                    .toString()
                    .toLowerCase()
                    .contains('rain')
                ? Icons.water_drop
                : Icons.wb_sunny,
            size: 32,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            '${temp.round()}${_getTemperatureUnit()}',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Humidity ${dayForecast['main']['humidity']}%',
            style: const TextStyle(color: Colors.white),
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
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert,
                        color: Color.fromARGB(255, 0, 0, 0)),
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
              const SizedBox(height: 16),
              _buildAdditionalWeatherStats(),
            ],
          ),
        ),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wind Speed'),
              Text('$windSpeed m/s'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wind Direction'),
              Text('$windDirection°'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pressure'),
              Text('$pressure hPa'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Visibility'),
              Text('${visibility.toStringAsFixed(1)} km'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sunrise'),
              Text(DateFormat('HH:mm').format(sunrise)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sunset'),
              Text(DateFormat('HH:mm').format(sunset)),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
