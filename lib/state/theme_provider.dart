import 'package:flutter/material.dart';

/// Applies backend-sent theme configuration with sensible fallback defaults.
///
/// The backend may send theme data as part of the SDUI protocol. Until
/// backend theme is received, the provider exposes a default Material theme.
class ThemeProvider extends ChangeNotifier {
  ThemeData? _backendTheme;

  /// The resolved theme: backend-provided if available, otherwise null
  /// (callers should fall back to AppTheme defaults).
  ThemeData? get backendTheme => _backendTheme;
  bool get hasBackendTheme => _backendTheme != null;

  /// Apply a theme config received from the backend protocol.
  void applyBackendTheme(Map<String, dynamic> themeConfig) {
    _backendTheme = _buildThemeFromConfig(themeConfig);
    notifyListeners();
  }

  /// Clear backend theme (reverts to app defaults).
  void clearBackendTheme() {
    _backendTheme = null;
    notifyListeners();
  }

  ThemeData _buildThemeFromConfig(Map<String, dynamic> config) {
    final colors = config['colors'] as Map<String, dynamic>? ?? {};
    final typography = config['typography'] as Map<String, dynamic>? ?? {};
    final spacing = config['spacing'] as Map<String, dynamic>? ?? {};

    final primaryColor = _parseColor(colors['primary']) ?? Colors.blue;
    final secondaryColor = _parseColor(colors['secondary']) ?? Colors.blueAccent;
    final backgroundColor = _parseColor(colors['background']) ?? Colors.white;
    final surfaceColor = _parseColor(colors['surface']) ?? Colors.white;
    final errorColor = _parseColor(colors['error']) ?? Colors.red;
    final onPrimaryColor = _parseColor(colors['on_primary']) ?? Colors.white;
    final onSurfaceColor = _parseColor(colors['on_surface']) ?? Colors.black87;

    final baseFontSize = (typography['base_font_size'] as num?)?.toDouble() ?? 14.0;
    final fontFamily = typography['font_family'] as String?;
    final density = (spacing['density'] as num?)?.toDouble();

    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: onPrimaryColor,
        onSurface: onSurfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: fontFamily,
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: baseFontSize),
        bodyLarge: TextStyle(fontSize: baseFontSize * 1.15),
        bodySmall: TextStyle(fontSize: baseFontSize * 0.85),
        titleLarge: TextStyle(fontSize: baseFontSize * 1.7),
        titleMedium: TextStyle(fontSize: baseFontSize * 1.3),
        headlineMedium: TextStyle(fontSize: baseFontSize * 2.0),
      ),
      visualDensity: density != null
          ? VisualDensity(horizontal: density, vertical: density)
          : VisualDensity.standard,
    );
  }

  Color? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is String && value.startsWith('#')) {
      final hex = value.replaceFirst('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    }
    return null;
  }
}
