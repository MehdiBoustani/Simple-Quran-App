import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/quran_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isSepia = false;

  void updateThemeMode(ThemeMode themeMode, bool isSepia) {
    setState(() {
      _themeMode = themeMode;
      _isSepia = isSepia;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coran',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(isSepia: _isSepia),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode,
      home: QuranScreen(onThemeToggle: updateThemeMode, isSepia: _isSepia),
    );
  }
}
