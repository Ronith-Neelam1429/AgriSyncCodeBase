import 'package:agrisync/App Pages/HomePage.dart';
import 'package:agrisync/App Pages/Core Pages/ProfilePage.dart';
import 'package:agrisync/App Pages/Core Pages/WeatherPage.dart';
import 'package:agrisync/App Pages/Core Pages/MarketPage.dart';
import 'package:agrisync/Authentication/Pages/forum_page.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class HomePageWithNavBar extends StatefulWidget {
  const HomePageWithNavBar({Key? key}) : super(key: key);

  @override
  _HomePageWithNavBarState createState() => _HomePageWithNavBarState();
}

class _HomePageWithNavBarState extends State<HomePageWithNavBar> {
  int _currentIndex = 0;
  List<Widget> _pages = [
    const HomePage(),
    const WeatherPage(),
    const MarketPlacePage(),
    const ProfilePage(),
    const ForumPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 39, 39, 39),
              Color.fromARGB(255, 38, 38, 38),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: CurvedNavigationBar(
          height: 65,
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          color: Colors.transparent,
          buttonBackgroundColor: const Color.fromARGB(255, 87, 189, 179),
          items: const <Widget>[
            Icon(Icons.home, size: 30, color: Colors.white),
            Icon(Icons.cloud, size: 30, color: Colors.white),
            Icon(Icons.shopping_cart, size: 30, color: Colors.white),
            Icon(Icons.person, size: 30, color: Colors.white),
            Icon(Icons.forum, size: 30, color: Colors.white),
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