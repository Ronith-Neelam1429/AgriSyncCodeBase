import 'package:agrisync/App Pages/HomePage.dart';
import 'package:agrisync/App%20Pages/Analytics/AIChatbotPage.dart';
import 'package:agrisync/App%20Pages/Analytics/AnalyticsPage.dart';
import 'package:agrisync/App%20Pages/MarketPlace/MarketPage.dart';
import 'package:agrisync/App%20Pages/ProfilePage/ProfilePage.dart';
import 'package:agrisync/App%20Pages/Analytics/YieldForecastPage.dart';
import 'package:agrisync/App%20Pages/Weather/WeatherPage.dart';
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
    HomePage(),
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
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
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
          
          height: 55,
          backgroundColor: Colors.transparent,
          color: Colors.transparent,
          buttonBackgroundColor: const Color.fromARGB(255, 98, 210, 201),
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
          items: const <Widget>[
            Icon(Icons.home, size: 25, color: Colors.white),
            Icon(Icons.wb_sunny, size: 25, color: Colors.white),
            Icon(Icons.shopping_cart, size: 25, color: Colors.white),
            Icon(Icons.person, size: 25, color: Colors.white),
            Icon(Icons.show_chart, size: 25, color: Colors.white),
            Icon(Icons.chat, size: 25, color: Colors.white),   
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
