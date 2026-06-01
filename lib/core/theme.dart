import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors (Day/Evening usage)
  static const Color lightBg = Color(0xFFF8FAF9);
  static const Color lightSurface = Colors.white;
  static const Color lightPrimary = Color(0xFF00695C); // Deep Forest Teal
  static const Color lightPrimaryContainer = Color(0xFFE0F2F1); // Light Mint
  static const Color lightSecondary = Color(0xFF004D40);
  static const Color lightAccent = Color(0xFFE65100); // Warm Orange for pending/payment
  static const Color lightTextPrimary = Color(0xFF1C2D27);
  static const Color lightTextSecondary = Color(0xFF5A6E66);
  static const Color lightBorder = Color(0xFFE0E6E3);

  // Dark Theme Colors (Morning 4 AM usage)
  static const Color darkBg = Color(0xFF0C1412); // Very deep charcoal green-black
  static const Color darkSurface = Color(0xFF14221D); // Card background
  static const Color darkPrimary = Color(0xFF26A69A); // Bright Mint Teal
  static const Color darkPrimaryContainer = Color(0xFF004D40); // Dark Teal
  static const Color darkSecondary = Color(0xFF80CBC4);
  static const Color darkAccent = Color(0xFFFFB300); // Yellow/Amber for visibility
  static const Color darkTextPrimary = Color(0xFFF1F5F3);
  static const Color darkTextSecondary = Color(0xFF9CAEAA);
  static const Color darkBorder = Color(0xFF223530);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        background: lightBg,
        surface: lightSurface,
        primary: lightPrimary,
        primaryContainer: lightPrimaryContainer,
        secondary: lightSecondary,
        error: Colors.redAccent,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: lightTextPrimary, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: lightTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: lightTextSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: lightTextPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56), // Large tap target for fast entry
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        space: 24,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        background: darkBg,
        surface: darkSurface,
        primary: darkPrimary,
        primaryContainer: darkPrimaryContainer,
        secondary: darkSecondary,
        error: Colors.redAccent,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkTextPrimary, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkTextPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkBg, // dark text on mint background
          elevation: 0,
          minimumSize: const Size(double.infinity, 56), // Large tap target for fast entry
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        space: 24,
        thickness: 1,
      ),
    );
  }
}
