import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agrisync/Authentication/Pages/LogOrSignPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSync',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginOrRegisterPage(),
    );
  }
}