import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class YieldForecastPage extends StatefulWidget {
  const YieldForecastPage({super.key});

  @override
  _YieldForecastPageState createState() => _YieldForecastPageState();
}

class _YieldForecastPageState extends State<YieldForecastPage> {
  final _farmSizeController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final _expectedYieldController = TextEditingController();
  String? _forecastResult;
  bool _isLoading = false;
  final String weatherApiKey = 'eeaca43a04ac307588b75ac98f9871d7'; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _farmSizeController.text = data['farmSize'] ?? '';
          _cropTypeController.text = (data['preferredCrops'] as List?)?.join(', ') ?? '';
        });
      }
    }
  }

  Future<void> _calculateForecast() async {
    setState(() {
      _isLoading = true;
      _forecastResult = null;
    });

    final farmSize = double.tryParse(_farmSizeController.text) ?? 0.0;
    final expectedYield = double.tryParse(_expectedYieldController.text) ?? 0.0;
    final cropType = _cropTypeController.text.trim();

    if (farmSize <= 0 || expectedYield <= 0 || cropType.isEmpty) {
      setState(() {
        _forecastResult = 'Please enter valid farm size, yield, and crop type.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch historical weather
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = data['lat'] ?? '51.5074'; // backup to London if error
          final lon = data['lon'] ?? '-0.1278';

          final weatherUrl =
              'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric';
          final weatherResponse = await http.get(Uri.parse(weatherUrl));
          if (weatherResponse.statusCode == 200) {
            final weatherData = json.decode(weatherResponse.body);
            final temp = weatherData['main']['temp'];
            final condition = weatherData['weather'][0]['main'];

            // Simple revenue forecast model 
            double marketPricePerUnit = _getMarketPrice(cropType); // Hypothetical prices
            double weatherFactor = condition.contains('Rain') ? 1.1 : 0.9;
            double revenue = (expectedYield * farmSize * marketPricePerUnit) * weatherFactor;

            // Save forecast to Firestore
            await FirebaseFirestore.instance.collection('forecasts').doc(user.uid).set({
              'farmSize': farmSize,
              'cropType': cropType,
              'expectedYield': expectedYield,
              'revenueForecast': revenue,
              'timestamp': FieldValue.serverTimestamp(),
            });

            setState(() {
              _forecastResult =
                  'Estimated Revenue: \$${revenue.toStringAsFixed(2)} based on $expectedYield tons/acre, $farmSize acres, and $condition weather at $temp°C';
              _isLoading = false;
            });
          } else {
            setState(() {
              _forecastResult = 'Failed to fetch weather data.';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _forecastResult = 'Error calculating forecast: $e';
        _isLoading = false;
      });
    }
  }

  double _getMarketPrice(String cropType) {
    // Hypothetical market prices (in $/ton)
    const Map<String, double> cropPrices = {
      'Corn': 200.0,
      'Soybeans': 400.0,
      'Wheat': 250.0,
    };
    return cropPrices[cropType] ?? 300.0; // Default price if crop is not found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yield & Revenue Forecast'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _farmSizeController,
                    decoration: const InputDecoration(labelText: 'Farm Size (acres)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cropTypeController,
                    decoration: const InputDecoration(labelText: 'Crop Type (e.g., Corn, Soybeans)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _expectedYieldController,
                    decoration: const InputDecoration(labelText: 'Expected Yield (tons/acre)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _calculateForecast,
                    child: const Text('Calculate Forecast'),
                  ),
                  const SizedBox(height: 20),
                  if (_forecastResult != null)
                    Text(
                      _forecastResult!,
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
      ),
    );
  }
}