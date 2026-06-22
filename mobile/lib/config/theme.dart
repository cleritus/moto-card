import 'package:flutter/material.dart';

class AppColors {
  // Dark theme - Ironside (black / red / industrial)
  static const Color darkBackground = Color(0xFF0D0D0D); // tło główne
  static const Color darkSurface = Color(0xFF1A1A1A); // tło kart
  static const Color darkSurfaceBright = Color(0xFF242424); // inputy / wewnętrzne
  static const Color darkPrimary = Color(0xFFCC2200); // główny akcent (czerwień)
  static const Color darkAccent = Color(0xFFFF3B1F); // podświetlenia, chevron
  static const Color darkSecondary = darkAccent; // alias zgodności
  static const Color darkBorder = Color(0xFF2E2E2E); // obramowania
  static const Color darkLabel = Color(0xFF888888); // etykiety UPPERCASE szare
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnBackground = Color(0xFFFFFFFF); // tekst główny
  static const Color darkOnSurface = Color(0xFFCCCCCC); // tekst drugorzędny

  // Light theme - metallic/blue/white (pozostawione dla zgodności)
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
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.darkSurface,
          primary: AppColors.darkPrimary,
          secondary: AppColors.darkAccent,
          onPrimary: AppColors.darkOnPrimary,
          onSurface: AppColors.darkOnSurface,
          outline: AppColors.darkBorder,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.darkOnPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.all<Color>(AppColors.darkPrimary),
            foregroundColor:
                WidgetStateProperty.all<Color>(AppColors.darkOnPrimary),
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 16),
            ),
            shape: WidgetStateProperty.all<OutlinedBorder>(
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            textStyle: WidgetStateProperty.all<TextStyle>(
              const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkOnBackground,
            side: const BorderSide(color: AppColors.darkBorder),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceBright,
          labelStyle: const TextStyle(color: AppColors.darkLabel),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.darkPrimary),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.darkPrimary,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurface,
          actionTextColor: AppColors.darkPrimary,
          contentTextStyle: TextStyle(color: AppColors.darkOnBackground),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.darkBorder),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
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
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
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
