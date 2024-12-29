import 'package:agrisync/App%20Pages/Weather%20Page/LocationService.dart';
import 'package:agrisync/App%20Pages/Weather%20Page/WeatherCard.dart';
import 'package:agrisync/Components/CustomAppBar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _displayName;
  String? _profileImageUrl;
  String? _userCity;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      }); 

      // First try to get the current location
      await _updateUserLocation();

      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _displayName = '${userData['firstName']} ${userData['lastName']}';
            _profileImageUrl = userData['profileImageUrl'] ??
                'https://ui-avatars.com/api/?name=${userData['firstName']}+${userData['lastName']}';
          });
        } else if (user.providerData
            .any((provider) => provider.providerId == 'google.com')) {
          setState(() {
            _displayName = user.displayName ?? 'User';
            _profileImageUrl = user.photoURL ??
                'https://ui-avatars.com/api/?name=${user.displayName}';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _displayName = 'User';
        _profileImageUrl = 'https://ui-avatars.com/api/?name=User';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _updateUserLocation() async {
    print('Updating user location...');
    try {
      final locationData = await LocationService.getCurrentLocation();
      
      if (locationData != null) {
        print('Location data received: ${locationData['city']}');
        setState(() {
          _userCity = locationData['city'];
        });
        
        if (_auth.currentUser != null) {
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'city': locationData['city'],
            'latitude': locationData['latitude'],
            'longitude': locationData['longitude'],
          });
        }
      } else {
        print('No location data received, using default city');
        setState(() {
          _userCity = 'London'; // Default city
        });
      }
    } catch (e) {
      print('Error updating location: $e');
      setState(() {
        _userCity = 'London'; // Default city
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_displayName != null)
              CustomAppBar(
                name: _displayName!,
                profileImageUrl: _profileImageUrl ??
                    'https://ui-avatars.com/api/?name=$_displayName',
              ),
            if (_displayName == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Todays Weather',
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_isLoadingLocation)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_userCity != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: WeatherCard(
                  apiKey: 'eeaca43a04ac307588b75ac98f9871d7',
                  city: _userCity!,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('Unable to load weather data'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}