import 'package:flutter/material.dart';
import 'nomnom_colors.dart';

class NomNomTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: NomNomColors.primary,
      onPrimary: Colors.white,
      secondary: NomNomColors.secondary,
      onSecondary: Colors.white,
      error: NomNomColors.error,
      onError: Colors.white,
      background: NomNomColors.background,
      onBackground: NomNomColors.textPrimary,
      surface: NomNomColors.surface,
      onSurface: NomNomColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NomNomColors.background,
      fontFamily: null,

      appBarTheme: const AppBarTheme(
        backgroundColor: NomNomColors.surface,
        foregroundColor: NomNomColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: NomNomColors.textPrimary,
        ),
      ),

      cardTheme: const CardThemeData(
        color: NomNomColors.surface,
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NomNomColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NomNomColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 1,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NomNomColors.primaryDeep,
        ),
      ),

      iconTheme: const IconThemeData(
        color: NomNomColors.textPrimary,
      ),

      dividerColor: NomNomColors.border,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NomNomColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NomNomColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NomNomColors.primary),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: NomNomColors.secondaryLight,
        selectedColor: NomNomColors.secondary,
        labelStyle: const TextStyle(
          color: NomNomColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: NomNomColors.primaryDeep,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: NomNomColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NomNomColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: NomNomColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: NomNomColors.textSecondary,
        ),
      ),
    );
  }
  
  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: NomNomColors.darkPrimary,
      onPrimary: Colors.black,
      secondary: NomNomColors.darkSecondary,
      onSecondary: Colors.white,
      error: NomNomColors.darkError,
      onError: Colors.black,
      background: NomNomColors.darkBackground,
      onBackground: NomNomColors.darkTextPrimary,
      surface: NomNomColors.darkSurface,
      onSurface: NomNomColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NomNomColors.darkBackground,
      fontFamily: null,

      appBarTheme: const AppBarTheme(
        backgroundColor: NomNomColors.darkSurface,
        foregroundColor: NomNomColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: NomNomColors.darkTextPrimary,
        ),
      ),

      cardTheme: const CardThemeData(
        color: NomNomColors.darkSurface,
        elevation: 1,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NomNomColors.darkPrimary,
        foregroundColor: Colors.black,
        shape: CircleBorder(),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NomNomColors.darkPrimary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 1,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NomNomColors.darkPrimary,
        ),
      ),

      iconTheme: const IconThemeData(
        color: NomNomColors.darkTextPrimary,
      ),

      dividerColor: NomNomColors.darkBorder,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NomNomColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NomNomColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NomNomColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NomNomColors.darkPrimary),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: NomNomColors.darkSecondaryContainer,
        selectedColor: NomNomColors.darkSecondary,
        labelStyle: const TextStyle(
          color: NomNomColors.darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: NomNomColors.darkPrimaryDeep,
        contentTextStyle: TextStyle(color: Colors.black),
        behavior: SnackBarBehavior.floating,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: NomNomColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NomNomColors.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: NomNomColors.darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: NomNomColors.darkTextSecondary,
        ),
      ),
    );
  }
}
