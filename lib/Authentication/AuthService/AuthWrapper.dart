import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrisync/Components/CustomNavBar.dart';
import 'package:agrisync/Authentication/Pages/LogOrSignPage.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true; // Tracks if we’re still checking auth
  bool _isLoggedIn = false; // Tracks if user is logged in

  @override
  void initState() {
    super.initState();
    _checkAuthState(); // Check auth status when the widget starts
  }

  // Checks if a user is logged in with Firebase
  Future<void> _checkAuthState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // User’s logged in, so show the app
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
    } else {
      // No user, kick them to login
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a spinner while checking auth
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Decide what to show based on login status
    if (_isLoggedIn) {
      return const CustomNavBar(); // Main app with nav bar
    } else {
      return const LoginOrRegisterPage(); // Login/signup screen
    }
  }
}