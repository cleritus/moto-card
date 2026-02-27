import 'package:flutter/material.dart';

class AppColors {
  // Dark theme - black/red
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFFE53935); // Red
  static const Color darkSecondary = Color(0xFFFF5252);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFBDBDBD);

  // Light theme - metallic/blue/white
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF1565C0); // Blue
  static const Color lightSecondary = Color(0xFF607D8B); // Metallic
  static const Color lightOnBackground = Color(0xFF212121);
  static const Color lightOnSurface = Color(0xFF424242);
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.darkSurface,
          primary: AppColors.darkPrimary,
          secondary: AppColors.darkSecondary,
          onSurface: AppColors.darkOnSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkOnBackground,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          surface: AppColors.lightSurface,
          primary: AppColors.lightPrimary,
          secondary: AppColors.lightSecondary,
          onSurface: AppColors.lightOnSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightSurface,
          foregroundColor: AppColors.lightOnBackground,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
        ),
      );
}
