import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0b2351);
  static const Color surfaceColor = Color(0xFF1a1a1a);
  static const Color cardColor = Color(0xFF2d2d2d);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: primaryColor,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: surfaceColor,
        onSurface: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white10,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}