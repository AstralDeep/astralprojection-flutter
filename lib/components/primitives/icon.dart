import 'package:flutter/material.dart';

class IconWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;

  const IconWidget({
    required this.primitive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final config = primitive['config'] as Map<String, dynamic>? ?? {};

    // --- Parse Config ---
    final String? iconName = config['iconName']?.toString();
    final String? title = config['title']?.toString();
    
    // Use helper functions to parse CSS-like values
    final double size = _parseDouble(config['size']) ?? 24.0; // Default to 24
    final Color color = _parseColor(config['color']) ?? Theme.of(context).iconTheme.color ?? Colors.black;

    // --- Create the Icon ---
    final icon = Icon(
      _mapStringToIconData(iconName), // Map the name to an IconData
      size: size,
      color: color,
    );

    // If a title is provided, wrap the icon in a Tooltip for accessibility.
    if (title != null && title.isNotEmpty) {
      return Tooltip(
        message: title,
        child: icon,
      );
    }

    return icon;
  }
}

/// Maps a string name to a corresponding Material IconData.
/// This is the equivalent of the `getSvgPath` function in your React code.
IconData _mapStringToIconData(String? iconName) {
  switch (iconName?.toLowerCase()) {
    case 'close':
      return Icons.close;
    case 'user':
      return Icons.person;
    case 'settings':
      return Icons.settings;
    case 'home':
      return Icons.home;
    case 'search':
      return Icons.search;
    case 'check':
    case 'check_circle':
      return Icons.check_circle;
    case 'info':
      return Icons.info_outline;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'error':
      return Icons.error_outline;
    case 'delete':
      return Icons.delete_outline;
    case 'edit':
      return Icons.edit;
    // Add more mappings as needed for your app
    default:
      // Return a default placeholder icon if the name is unknown
      return Icons.circle_outlined;
  }
}


// --- Style Parsing Helpers (can be moved to a shared utility file) ---

double? _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    // Remove "px", "em", etc., and parse the number
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
  }
  return null;
}

Color? _parseColor(String? value) {
  if (value == null) return null;

  // Handle 'currentColor' case
  if (value.toLowerCase() == 'currentcolor') {
    // Returning null will allow the Icon widget to inherit color from the theme
    return null;
  }

  String hex = value.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 3) {
    hex = hex.split('').map((c) => c + c).join('');
  }
  if (hex.length == 6) {
    hex = 'FF$hex'; // Add alpha if missing
  }
  if (hex.length == 8) {
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue != null) {
      return Color(intValue);
    }
  }
  return null; // Return null if parsing fails
}