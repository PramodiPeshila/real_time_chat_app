import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    onPrimaryFixed: const Color.fromARGB(255, 26, 132, 219),
    primary: Colors.white,
    secondary: const Color.fromARGB(255, 218, 218, 218),
    tertiary: Colors.lightGreenAccent,
    onTertiary: Colors.redAccent
  ),
);