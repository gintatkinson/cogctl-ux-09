import 'package:flutter/material.dart';

class GcpThemeFactory {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF3367D6), // Google Cloud Primary Action Blue
      scaffoldBackgroundColor: const Color(0xFFF9F9F9), // GCP Console Canvas Background
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF3367D6),
        secondary: Color(0xFF3367D6),
        surface: Colors.white,
        error: Color(0xFFD93025), // GCP Red Error
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1), // GCP solid light gray border
          borderRadius: BorderRadius.circular(4), // Boxy GCP corners
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFF3C4043)),
        titleMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFF202124), fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF3367D6), // Classic GCP Console Header Blue
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF8AB4F8), // GCP Light Blue for Dark Mode
      scaffoldBackgroundColor: const Color(0xFF202124), // GCP Dark Gray Background
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8AB4F8),
        secondary: Color(0xFF8AB4F8),
        surface: Color(0xFF303134), // GCP Darker card background
        error: Color(0xFFF28B82), // GCP Light Red Error for Dark Mode
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF303134),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF3C4043), width: 1), // Dark mode card border
          borderRadius: BorderRadius.circular(4), // Boxy GCP corners
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFFE8EAED)),
        titleMedium: TextStyle(fontFamily: 'Roboto', color: Color(0xFFF1F3F4), fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF303134), // GCP Console Header Dark Gray
        foregroundColor: Colors.white,
      ),
    );
  }
}
