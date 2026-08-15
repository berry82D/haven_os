import 'package:flutter/material.dart';

class AppTheme {
  static const Color paper = Color(0xFFF5EDE0);
  static const Color ink = Color(0xFF3E2C1B);
  static const Color accent = Color(0xFF7C9A6E);
  static const Color tornEdge = Color(0xFFD4C5A0);
  static const Color error = Color(0xFFB33A3A);

  // ========== FARM BACKGROUND DECORATION ==========
  static BoxDecoration farmBackground = BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/farm_background.jpg'),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.white.withValues(alpha: 0.85),
        BlendMode.modulate,
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: accent,
    fontFamily: 'serif',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'serif',
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.85),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tornEdge, width: 1),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: ink, fontFamily: 'serif'),
      bodyMedium: TextStyle(color: ink, fontFamily: 'serif'),
      titleLarge: TextStyle(
          color: ink, fontFamily: 'serif', fontWeight: FontWeight.bold),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: accent,
    fontFamily: 'serif',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.black.withValues(alpha: 0.7),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade700, width: 0.5),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontFamily: 'serif'),
      bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'serif'),
      titleLarge: TextStyle(
          color: Colors.white,
          fontFamily: 'serif',
          fontWeight: FontWeight.bold),
    ),
  );
}
