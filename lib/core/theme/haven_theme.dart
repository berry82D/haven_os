// lib/core/theme/haven_theme.dart
import 'package:flutter/material.dart';
import 'package:haven_os/core/constants/colors.dart';

class HavenTheme {
  static ThemeData get light {
    return ThemeData(
      primaryColor: HavenColors.green,
      colorScheme: ColorScheme.light(
        primary: HavenColors.green,
        secondary: HavenColors.mutedGreen,
        surface: HavenColors.cream,
        onSurface: HavenColors.dark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: HavenColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
        titleTextStyle: TextStyle(
          color: HavenColors.dark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: HavenColors.dark,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: HavenColors.dark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: HavenColors.dark,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: HavenColors.muted,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: HavenColors.white,
        labelStyle: const TextStyle(color: HavenColors.muted),
        prefixIconColor: HavenColors.muted,
        suffixIconColor: HavenColors.muted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HavenColors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        // fixed: use CardThemeData instead of CardTheme
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: HavenColors.white,
      ),
    );
  }
}
