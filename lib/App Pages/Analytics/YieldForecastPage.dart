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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = data['lat'] ?? '51.5074';
          final lon = data['lon'] ?? '-0.1278';

          final weatherUrl = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric';
          final weatherResponse = await http.get(Uri.parse(weatherUrl));
          if (weatherResponse.statusCode == 200) {
            final weatherData = json.decode(weatherResponse.body);
            final temp = weatherData['main']['temp'];
            final condition = weatherData['weather'][0]['main'];

            double marketPricePerUnit = _getMarketPrice(cropType);
            double weatherFactor = condition.contains('Rain') ? 1.1 : 0.9;
            double revenue = (expectedYield * farmSize * marketPricePerUnit) * weatherFactor;

            await FirebaseFirestore.instance.collection('forecasts').doc(user.uid).set({
              'farmSize': farmSize,
              'cropType': cropType,
              'expectedYield': expectedYield,
              'revenueForecast': revenue,
              'timestamp': FieldValue.serverTimestamp(),
            });

            setState(() {
              _forecastResult =
                  'Estimated Revenue: \$${revenue.toStringAsFixed(2)}\nBased on: $expectedYield tons/acre, $farmSize acres,\n$condition weather at $temp°C';
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
    const Map<String, double> cropPrices = {
      'Corn': 200.0,
      'Soybeans': 400.0,
      'Wheat': 250.0,
    };
    return cropPrices[cropType] ?? 300.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yield & Revenue Forecast', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _farmSizeController,
                      decoration: InputDecoration(
                        labelText: 'Farm Size (acres)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cropTypeController,
                      decoration: InputDecoration(
                        labelText: 'Crop Type (e.g., Corn, Soybeans)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _expectedYieldController,
                      decoration: InputDecoration(
                        labelText: 'Expected Yield (tons/acre)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _calculateForecast,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 66, 192, 201),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Calculate Forecast', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_forecastResult != null)
                      Card(
                        color: Colors.grey[100],
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _forecastResult!,
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
