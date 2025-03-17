import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
      surface: const Color.fromARGB(255, 255, 255, 255),
      primary: Colors.grey.shade300,
      secondary: const Color.fromARGB(255, 255, 255, 255),
      tertiary: Colors.black,
      inversePrimary: Colors.black),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
      surface: Colors.grey.shade900,
      primary: const Color.fromARGB(255, 255, 255, 255),
      secondary: const Color.fromARGB(255, 255, 255, 255),
      tertiary: Colors.white,
      inversePrimary: Colors.white),
);
