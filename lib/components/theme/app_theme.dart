import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Defines the color palette for the University of Kentucky theme.
class _UKColors {
  static const Color wildcatBlue = Color(0xFF0033A0);
  static const Color bluegrass = Color(0xFF1E8AFF);
  static const Color midnight = Color(0xFF1B365D);
  static const Color darkText = Color(0xFF212121);
  static const Color lightText = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  // ignore: unused_field, may be used for future theme elements
  static const Color grey = Color(0xFF8E8E8E);
}

// Main class for the application's theme.
class AppTheme {
  // Common text theme setup used by both light and dark themes.
  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.lato(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: GoogleFonts.lato(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: GoogleFonts.lato(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.w400),
    headlineMedium: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.w400),
    headlineSmall: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700),
    titleSmall: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700),
    labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w400),
  );

  /// **LightTheme** for the application.
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _UKColors.wildcatBlue,
    scaffoldBackgroundColor: _UKColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: _UKColors.wildcatBlue,
      secondary: _UKColors.bluegrass,
      surface: Colors.white,
      error: Colors.red,
      onPrimary: _UKColors.lightText,
      onSecondary: _UKColors.lightText,
      onSurface: _UKColors.darkText,
      onError: _UKColors.lightText,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _UKColors.wildcatBlue,
      elevation: 0,
      iconTheme: IconThemeData(color: _UKColors.lightText),
    ),
    textTheme: _textTheme.apply(
      bodyColor: _UKColors.darkText,
      displayColor: _UKColors.darkText,
    ),
    iconTheme: const IconThemeData(
      color: _UKColors.wildcatBlue,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _UKColors.lightText,
        backgroundColor: _UKColors.wildcatBlue,
      ),
    ),
  );

  /// **DarkTheme** for the application.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _UKColors.wildcatBlue,
    scaffoldBackgroundColor: _UKColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: _UKColors.wildcatBlue,
      secondary: _UKColors.bluegrass,
      surface: _UKColors.darkSurface,
      error: Colors.redAccent,
      onPrimary: _UKColors.lightText,
      onSecondary: _UKColors.lightText,
      onSurface: _UKColors.lightText,
      onError: _UKColors.darkText,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _UKColors.midnight,
      elevation: 0,
      iconTheme: IconThemeData(color: _UKColors.lightText),
    ),
    textTheme: _textTheme.apply(
      bodyColor: _UKColors.lightText,
      displayColor: _UKColors.lightText,
    ),
    iconTheme: const IconThemeData(
      color: _UKColors.bluegrass,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _UKColors.lightText,
        backgroundColor: _UKColors.wildcatBlue,
      ),
    ),
  );
}