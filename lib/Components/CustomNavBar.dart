import 'package:agrisync/App%20Pages/HomePage.dart';
import 'package:agrisync/App%20Pages/MonitorPage.dart';
import 'package:agrisync/App%20Pages/ProfilePage.dart';
import 'package:agrisync/App%20Pages/WeatherPage.dart';
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
    const MonitorPage(),
    const ProfilePage(),
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

        //Making our bottom navigation bar (container) have
        //A curved navigation bar as it's object
        child: CurvedNavigationBar(
          height: 65,
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          color: Colors.transparent,
          buttonBackgroundColor: const Color.fromARGB(255, 87, 189, 179),

          //Creating the icons/images for each picture and assigning their pages to them
          items: const <Widget>[
            Icon(Icons.home, size: 30, color: Colors.white),
            Icon(Icons.cloud, size: 30, color: Colors.white),
            Icon(Icons.trending_up, size: 30, color: Colors.white),
            Icon(Icons.person, size: 30, color: Colors.white),
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
