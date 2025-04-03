import 'package:agrisync/Authentication/AuthService/Google_Service.dart';
import 'package:agrisync/Components/CustomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController(); // For email input
  final passwordController = TextEditingController(); // For password input
  bool _rememberMe = false; // Tracks if "remember me" is checked
  bool _obscurePassword = true; // Hides or shows password
  bool _isLoading = false; // Shows spinner when signing in
  String? _errorMessage; // Holds any login errors
  final googleAuth = GoogleAuthService(); // Google sign-in helper
  final _prefs = SharedPreferences.getInstance(); // For saving login info

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // Check for saved login details when page loads
  }

  // Load saved credentials if they exist
  Future<void> _loadSavedCredentials() async {
    final prefs = await _prefs;
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        usernameController.text = prefs.getString('email') ?? '';
        passwordController.text = prefs.getString('password') ?? ''; // Fill in saved email/password
      }
    });
  }

  // Save or clear credentials based on "remember me"
  Future<void> _handleRememberMe() async {
    final prefs = await _prefs;
    if (_rememberMe) {
      await prefs.setString('email', usernameController.text);
      await prefs.setString('password', passwordController.text);
      await prefs.setBool('rememberMe', true); // Save the details
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false); // Wipe them out
    }
  }

  // Sign in with email and password
  Future<void> signUserIn() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true; // Show the spinner
      _errorMessage = null; // Clear old errors
    });

    try {
      // Get auth instance
      final auth = FirebaseAuth.instance;

      // Try to sign in and immediately get user
      final userCredential = await auth.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        await _handleRememberMe(); // Save credentials if remember me is checked

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomNavBar(), // Jump to main app
          ),
        );
      }

      final user = userCredential.user;

      // Only proceed if we actually got a user back
      if (user != null) {
        if (!mounted) return;

        // Navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomNavBar(),
          ),
        );
      } else {
        throw Exception('Failed to get user details');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No user found with this email';
            break;
          case 'wrong-password':
            _errorMessage = 'Wrong password';
            break;
          case 'invalid-email':
            _errorMessage = 'Invalid email format';
            break;
          default:
            _errorMessage = 'Login failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // Catch any weird errors
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop the spinner
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose(); // Clean up controllers
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
              style: const TextStyle(color: Colors.red), // Show error if there’s one
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: usernameController,
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
            controller: passwordController,
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
                    _obscurePassword = !_obscurePassword; // Toggle password visibility
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false; // Update remember me state
                    });
                  },
                  fillColor: MaterialStateProperty.all(Colors.transparent),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement forgot password functionality
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : signUserIn, // Disable button while loading
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
                    'Login',
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
          'Or login with',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  setState(() => _isLoading = true); // Start the spinner
                  print("Starting Google Sign In");
                  final userCredential = await googleAuth.signInWithGoogle();
                  print("Sign In Result: ${userCredential?.user?.email}");

                  if (userCredential != null && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomNavBar()), // Go to main app
                    );
                  }
                } catch (e, stackTrace) {
                  print('Error in button press: $e');
                  print('Stack trace: $stackTrace');
                  setState(() {
                    _errorMessage =
                        'Failed to sign in with Google: ${e.toString()}';
                  });
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false); // Stop the spinner
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
          ],
        ),
      ],
    );
  }
}