import 'package:flutter/material.dart';

class AppConfig {
  // App Info
  static const String appName = 'MyPlaylist';
  static const String appVersion = '2.9.0';
  static const String appAuthor = 'Massimo';
  static const String appBuildDate = '02/01/2026';

  // Window Layout
  static const Size windowSize = Size(1200, 800);

  // Theme Colors
  static const Color seedColor = Color(0xFF4CAF50);
  static const Color scaffoldBackgroundColor = Color(0xFF2B2B2B);
  static const Color surfaceColor = Color(0xFF2B2B2B);
  static const Color cardColor = Color(0xFF3C3C3C);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;

  // Themes
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        surface: surfaceColor,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
        ),
      ),
    );
  }
}
