import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
      surface: const Color.fromARGB(255, 247, 247, 247),
      primary: Colors.grey.shade300,
      secondary: const Color.fromARGB(255, 212, 212, 212),
      tertiary: Colors.black,
      inversePrimary: Colors.black),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
      surface: Colors.grey.shade900,
      primary: const Color.fromARGB(255, 255, 255, 255),
      secondary: const Color.fromARGB(255, 56, 56, 56),
      tertiary: Colors.white,
      inversePrimary: Colors.white),
);
