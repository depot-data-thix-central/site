import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color surfaceDark = Color(0xFF10203A);
  static const Color cardDark    = Color(0xFF0E1B31);
  static const Color gold        = Color(0xFFC9A227);
  static const Color goldLight   = Color(0xFFE3C04B);
  static const Color lightGray   = Color(0xFFF5F7FA);
  static const Color textMuted   = Color(0xFF8A94A6);
  static const Color success     = Color(0xFF16A34A);
  static const Color danger      = Color(0xFFDC2626);

  static const LinearGradient goldGradient =
      LinearGradient(colors: [Color(0xFFD9B23A), Color(0xFFB8860B)]);
  static const LinearGradient heroGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0B1B33), Color(0xFF0A1628), Color(0xFF071120)]);
}

class AppTheme {
  static const TextStyle buttonLabel = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: AppColors.primaryDark, letterSpacing: .3);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.dark(
            primary: AppColors.gold, surface: AppColors.primaryDark),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 44, height: 1.15,
              fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
              color: AppColors.primaryDark, letterSpacing: -0.3),
          titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.primaryDark),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        popupMenuTheme: const PopupMenuThemeData(
            color: AppColors.surfaceDark,
            textStyle: TextStyle(color: Colors.white, fontSize: 13)),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        fontFamily: 'Inter',
        fontFamilyFallback: const ['Inter', 'Segoe UI', 'Roboto',
            'Helvetica Neue', 'Arial', 'Noto Sans'],
      );
}
