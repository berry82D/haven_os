import 'package:flutter/material.dart';
import 'package:haven_os/core/constants/colors.dart';

class HavenTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: HavenColors.green,
      onPrimary: Colors.white,
      secondary: HavenColors.mutedGreen,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: HavenColors.cream,
      onSurface: HavenColors.dark,
    ),
    scaffoldBackgroundColor: HavenColors.cream,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: HavenColors.dark,
      elevation: 0,
    ),
  );
}
