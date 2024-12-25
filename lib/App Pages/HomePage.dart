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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user != null) {
        // First try to get data from Firestore
        final DocumentSnapshot userDoc = 
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // User registered with email/password
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _displayName = '${userData['firstName']} ${userData['lastName']}';
            // If we stored profile image URL in Firestore
            _profileImageUrl = userData['profileImageUrl'] ?? 
                'https://ui-avatars.com/api/?name=${userData['firstName']}+${userData['lastName']}';
          });
        } else if (user.providerData.any((provider) => provider.providerId == 'google.com')) {
          // User signed in with Google
          setState(() {
            _displayName = user.displayName ?? 'User';
            _profileImageUrl = user.photoURL ?? 
                'https://ui-avatars.com/api/?name=${user.displayName}';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Set default values if there's an error
      setState(() {
        _displayName = 'User';
        _profileImageUrl = 'https://ui-avatars.com/api/?name=User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_displayName != null) // Only show AppBar when data is loaded
              CustomAppBar(
                name: _displayName!,
                profileImageUrl: _profileImageUrl ?? 
                    'https://ui-avatars.com/api/?name=$_displayName',
              ),
            if (_displayName == null) // Show loading indicator while loading
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            // Rest of your content
          ],
        ),
      ),
    );
  }
}