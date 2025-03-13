import 'package:agrisync/App Pages/HomePage.dart';
import 'package:agrisync/App Pages/Core Pages/MarketPage.dart';
import 'package:agrisync/App Pages/Core Pages/ProfilePage.dart';
import 'package:agrisync/App Pages/Core Pages/WeatherPage.dart';
import 'package:agrisync/App Pages/Core Pages/YieldForecastPage.dart';
import 'package:agrisync/App Pages/Core Pages/AIChatbotPage.dart'; 
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({Key? key}) : super(key: key);

  @override
  _CustomNavBarState createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const WeatherPage(),
    const MarketPlacePage(),
    const ProfilePage(),
    const YieldForecastPage(),
    const AIChatbotPage(),  
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 58, 58, 58),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(66, 39, 39, 39).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: CurvedNavigationBar(
          height: 65,
          backgroundColor: Colors.transparent,
          color: Colors.transparent,
          buttonBackgroundColor: const Color.fromARGB(255, 98, 210, 201),
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
          items: const <Widget>[
            Icon(Icons.home, size: 35, color: Colors.white),
            Icon(Icons.wb_sunny, size: 35, color: Colors.white),
            Icon(Icons.shopping_cart, size: 35, color: Colors.white),
            Icon(Icons.person, size: 35, color: Colors.white),
            Icon(Icons.show_chart, size: 35, color: Colors.white),
            Icon(Icons.chat, size: 35, color: Colors.white),   
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
