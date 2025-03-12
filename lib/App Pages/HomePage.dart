import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'Welcome to\n',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Agri',
                    style: TextStyle(
                      fontSize: 28,
                      color: Color.fromARGB(255, 73, 167, 87),
                    ),
                  ),
                  TextSpan(
                    text: 'Sync',
                    style: TextStyle(
                      color: Color.fromARGB(255, 72, 219, 214),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your farm with ease',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}