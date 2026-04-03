import 'package:flutter/material.dart';

/// Compact theme optimized for Apple Watch glanceable updates (~200px viewport).
///
/// Uses smaller font sizes, tighter padding, and high-contrast colors
/// suitable for the watch form factor.
class WatchTheme {
  WatchTheme._();

  // -- Watch-specific palette --
  static const Color _background = Color(0xFF000000);
  static const Color _surface = Color(0xFF1C1C1E);
  static const Color _primary = Color(0xFF0A84FF); // SF-style blue
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFFFFFFFF);
  static const Color _onSurfaceVariant = Color(0xFF8E8E93);
  static const Color _error = Color(0xFFFF453A);

  /// Compact text theme scaled for ~200px watch viewport.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 9, fontWeight: FontWeight.w400),
  );

  /// The watch [ThemeData] — dark, compact, high-contrast.
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: _primary,
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.dark(
          primary: _primary,
          secondary: _primary,
          surface: _surface,
          error: _error,
          onPrimary: _onPrimary,
          onSecondary: _onPrimary,
          onSurface: _onSurface,
          onError: _onPrimary,
          brightness: Brightness.dark,
        ),
        // Compact card theme
        cardTheme: CardThemeData(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          color: _surface,
        ),
        // Compact button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: _onPrimary,
            backgroundColor: _primary,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            minimumSize: const Size(40, 28),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        ),
        // Compact icon size
        iconTheme: const IconThemeData(
          size: 16.0,
          color: _primary,
        ),
        // Compact divider
        dividerTheme: const DividerThemeData(
          space: 4.0,
          thickness: 0.5,
          color: _onSurfaceVariant,
        ),
        // Compact progress indicator
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          linearMinHeight: 3.0,
          color: _primary,
        ),
        // Text theme
        textTheme: _textTheme.apply(
          bodyColor: _onSurface,
          displayColor: _onSurface,
        ),
        // Visual density: compact
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  /// Maximum recommended viewport width for watch layout.
  static const double maxViewportWidth = 200.0;

  /// Standard compact padding for watch content.
  static const EdgeInsets contentPadding = EdgeInsets.all(4.0);
}
