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
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // User is logged in
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
    } else {
      // User is not logged in
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoggedIn) {
      return const CustomNavBar();
    } else {
      return const LoginOrRegisterPage();
    }
  }
}