import 'package:flutter/material.dart';

/// T071 -- Fallback TV theme with 1.5x text scale and generous spacing.
///
/// This theme is used when the device is detected as TV and no backend
/// theme has been received via ThemeProvider. It emphasises legibility
/// at typical living-room viewing distances and provides high-contrast
/// focus indicators for D-pad navigation.
class TvTheme {
  TvTheme._(); // Prevent instantiation.

  /// Text scale multiplier applied to all text in TV mode.
  static const double textScaleFactor = 1.5;

  /// Default content padding for TV layouts.
  static const EdgeInsets contentPadding = EdgeInsets.all(32.0);

  /// High-contrast focus border colour.
  static const Color focusBorderColor = Color(0xFFFFD600); // Amber/yellow

  /// Width of the focus indicator border.
  static const double focusBorderWidth = 3.0;

  /// The TV-optimised [ThemeData].
  static ThemeData get theme {
    const primaryColor = Color(0xFF6366F1);   // AstralColors.primary
    const secondaryColor = Color(0xFF8B5CF6); // AstralColors.secondary
    const backgroundColor = Color(0xFF0F1221); // AstralColors.background
    const surfaceColor = Color(0xFF1A1E2E);   // AstralColors.surface
    const onSurfaceColor = Color(0xFFF3F4F6); // AstralColors.text
    const onPrimaryColor = Color(0xFFF3F4F6); // AstralColors.text

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: onPrimaryColor,
        onSurface: onSurfaceColor,
      ),
      // Generous visual density for large-screen touch/dpad targets.
      visualDensity: const VisualDensity(horizontal: 4.0, vertical: 4.0),
      // Scaled-up text theme for readability at distance.
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 86, fontWeight: FontWeight.w400),
        displayMedium: TextStyle(fontSize: 68, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontSize: 54, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w400),
        headlineMedium: TextStyle(fontSize: 42, fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 33, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 21, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
      ),
      // High-contrast focus highlight for D-pad navigation.
      focusColor: focusBorderColor,
      // Generous button padding.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: onPrimaryColor,
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurfaceColor,
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          side: const BorderSide(color: secondaryColor, width: 2),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.all(16.0),
      ),
    );
  }
}
