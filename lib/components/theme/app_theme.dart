import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette matching the React frontend's dark navy theme.
/// Values extracted from React CSS variables (research.md R9).
class AstralColors {
  static const Color background = Color(0xFF0F1221);
  static const Color surface = Color(0xFF1A1E2E);
  static const Color primary = Color(0xFF6366F1); // indigo
  static const Color secondary = Color(0xFF8B5CF6); // purple
  static const Color text = Color(0xFFF3F4F6);
  static const Color accent = Color(0xFF06B6D4); // cyan
  static const Color darkText = Color(0xFF212121);
  static const Color error = Color(0xFFEF4444);
}

/// Main class for the application's theme.
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
    primaryColor: AstralColors.primary,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    colorScheme: const ColorScheme.light(
      primary: AstralColors.primary,
      secondary: AstralColors.secondary,
      tertiary: AstralColors.accent,
      surface: Colors.white,
      error: AstralColors.error,
      onPrimary: AstralColors.text,
      onSecondary: AstralColors.text,
      onSurface: AstralColors.darkText,
      onError: AstralColors.text,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AstralColors.primary,
      elevation: 0,
      iconTheme: IconThemeData(color: AstralColors.text),
    ),
    textTheme: _textTheme.apply(
      bodyColor: AstralColors.darkText,
      displayColor: AstralColors.darkText,
    ),
    iconTheme: const IconThemeData(
      color: AstralColors.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AstralColors.text,
        backgroundColor: AstralColors.primary,
      ),
    ),
  );

  /// **DarkTheme** for the application (matches React frontend).
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AstralColors.primary,
    scaffoldBackgroundColor: AstralColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AstralColors.primary,
      secondary: AstralColors.secondary,
      tertiary: AstralColors.accent,
      surface: AstralColors.surface,
      error: AstralColors.error,
      onPrimary: AstralColors.text,
      onSecondary: AstralColors.text,
      onSurface: AstralColors.text,
      onError: AstralColors.darkText,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AstralColors.surface,
      elevation: 0,
      iconTheme: IconThemeData(color: AstralColors.text),
    ),
    textTheme: _textTheme.apply(
      bodyColor: AstralColors.text,
      displayColor: AstralColors.text,
    ),
    iconTheme: const IconThemeData(
      color: AstralColors.accent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AstralColors.text,
        backgroundColor: AstralColors.primary,
      ),
    ),
  );
}
