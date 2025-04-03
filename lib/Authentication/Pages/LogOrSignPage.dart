import 'package:agrisync/Authentication/Pages/Login.dart';
import 'package:agrisync/Authentication/Pages/Register.dart';
import 'package:flutter/material.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({Key? key}) : super(key: key);

  @override
  _LoginOrRegisterPageState createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  bool showLoginPage = true; // Start with the login page showing

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the whole screen
      body: SafeArea(
        child: SingleChildScrollView(  // Added ScrollView here so it doesn’t overflow
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(  // Added SizedBox to give minimum height
              height: MediaQuery.of(context).size.height - 48, // Full height minus padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context), // Back button to leave the page
                  ),
                  const SizedBox(height: 32),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Welcome Back to\n',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Agri',
                          style: TextStyle(
                              fontSize: 28,
                              color: Color.fromARGB(255, 73, 167, 87)), // Green for "Agri"
                        ),
                        TextSpan(
                          text: 'Sync',
                          style:
                              TextStyle(color: Color.fromARGB(255, 72, 219, 214)), // Teal for "Sync"
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign-in to manage your business',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showLoginPage = true; // Switch to login view
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                showLoginPage ? Colors.white : Colors.transparent, // Highlight if active
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: showLoginPage ? Colors.black : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showLoginPage = false; // Switch to register view
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !showLoginPage ? Colors.white : Colors.transparent, // Highlight if active
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: !showLoginPage ? Colors.black : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: showLoginPage ? const LoginPage() : const RegisterPage(), // Show either login or register form
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}