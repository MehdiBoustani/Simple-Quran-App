import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme({bool isSepia = false}) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 107, 107, 112),
      ),
      scaffoldBackgroundColor: isSepia ? const Color(0xFFF5E6D3) : Colors.white,
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: isSepia ? const Color(0xFF5B4636) : Colors.black,
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 107, 107, 112),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      useMaterial3: true,
    );
  }
}
