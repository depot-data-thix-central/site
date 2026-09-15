import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0A1628);
  static const surface = Color(0xFF10203A);
  static const gold = Color(0xFFC9A227);
  static const goldLight = Color(0xFFE3C04B);
  static const muted = Color(0xFF8A94A6);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          surface: AppColors.surface,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.muted,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
      );
}
