import 'package:agrisync/Components/WeatherCard.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
          child: WeatherCard(
            apiKey: '6b3e8032410c9d6580271ce6a113a098',
            city: 'Seattle',
      )),
    );
  }
}
