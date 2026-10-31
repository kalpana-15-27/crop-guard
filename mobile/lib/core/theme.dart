import 'package:flutter/material.dart';

/// Premium Agricultural Technology Design System for CropGuard AI
class AppTheme {
  // Brand Color Palette (from Project Design System)
  static const Color deepForest = Color(0xFF163C2B);
  static const Color leafGreen = Color(0xFF2F7D4A);
  static const Color freshGreen = Color(0xFF6FAF55);
  static const Color lime = Color(0xFFA9C96A);
  static const Color warmBackground = Color(0xFFF6F7EF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1B2821);
  static const Color mutedText = Color(0xFF707D73);
  static const Color warningAmber = Color(0xFFE9A23B);
  static const Color errorRed = Color(0xFFC94C4C);

  // Border & Divider colors
  static const Color borderLight = Color(0xFFE2E6DF);
  static const Color surfaceMuted = Color(0xFFEDF0E8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: leafGreen,
      scaffoldBackgroundColor: warmBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: leafGreen,
        onPrimary: Colors.white,
        secondary: freshGreen,
        onSecondary: Colors.white,
        tertiary: lime,
        onTertiary: darkText,
        surface: cardWhite,
        onSurface: darkText,
        error: errorRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: warmBackground,
        foregroundColor: deepForest,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: deepForest,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: deepForest),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: leafGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: leafGreen,
          side: const BorderSide(color: leafGreen, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: leafGreen,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: mutedText, fontSize: 14),
        labelStyle: const TextStyle(color: darkText, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: leafGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed, width: 1.2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: leafGreen,
        unselectedItemColor: mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}
