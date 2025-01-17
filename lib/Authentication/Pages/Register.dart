import 'package:agrisync/Authentication/AuthService/Google_Service.dart';
import 'package:agrisync/Components/CustomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final googleAuth = GoogleAuthService();

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Error message
  String? _errorMessage;

  // Register with email and password
  Future<void> register() async {
  if (_passwordController.text.trim().isEmpty ||
      _firstNameController.text.trim().isEmpty ||
      _lastNameController.text.trim().isEmpty ||
      _emailController.text.trim().isEmpty) {
    setState(() {
      _errorMessage = 'All fields are required';
    });
    return;
  }

  if (_passwordController.text != _confirmPasswordController.text) {
    setState(() {
      _errorMessage = 'Passwords do not match';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Debug log for registration start
    print('Starting registration process');
    print('Email: ${_emailController.text.trim()}');
    print('First Name: ${_firstNameController.text.trim()}');
    print('Last Name: ${_lastNameController.text.trim()}');

    // Create user with email and password
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    print('Firebase Auth successful. UID: ${userCredential.user!.uid}');

    // Prepare user data
    final userData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'uid': userCredential.user!.uid,
    };

    print('Prepared user data: $userData');

    // Get reference to Firestore
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    try {
      // Attempt to write to Firestore
      print('Attempting to write to Firestore at path: users/${userCredential.user!.uid}');
      
      await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      print('Firestore write successful');

      // Verify the write
      final docSnapshot = await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (docSnapshot.exists) {
        print('Document verified in Firestore');
        print('Stored data: ${docSnapshot.data()}');
      } else {
        print('WARNING: Document not found after write!');
      }

    } catch (firestoreError) {
      print('Firestore error: $firestoreError');
      setState(() {
        _errorMessage = 'Error saving user data: $firestoreError';
      });
      // Consider whether to delete the Auth user if Firestore fails
      return;
    }

    // Only navigate if everything was successful
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePageWithNavBar()),
      );
    }

  } on FirebaseAuthException catch (e) {
    print('Firebase Auth error: ${e.code} - ${e.message}');
    setState(() {
      _errorMessage = getErrorMessage(e.code);
    });
  } catch (e) {
    print('Unexpected error: $e');
    setState(() {
      _errorMessage = 'An unexpected error occurred: $e';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
  // Helper method to get user-friendly error messages
  String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _firstNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'First Name',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.person_outline, color: Colors.green),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Last Name Field
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _lastNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Last Name',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.person_outline, color: Colors.green),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Email Address',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.green),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Confirm Password',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Or register with',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  setState(() => _isLoading = true);
                  final userCredential = await googleAuth.signInWithGoogle();
                  if (userCredential != null && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePageWithNavBar()),
                    );
                  }
                } catch (e) {
                  setState(() {
                    _errorMessage =
                        'Failed to sign in with Google: ${e.toString()}';
                  });
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              icon: Image.network(
                'https://www.google.com/favicon.ico',
                height: 24,
              ),
              label: const Text(
                'Google',
                style: TextStyle(color: Colors.grey),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: Image.network(
                'https://www.yahoo.com/favicon.ico',
                height: 24,
              ),
              label: const Text(
                'Yahoo',
                style: TextStyle(color: Colors.grey),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
