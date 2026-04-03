import 'package:flutter/material.dart';

/// Renders a colored alert banner from SDUI schema.
///
/// Schema: { type: "alert", message: "string",
///   variant: "info"|"success"|"warning"|"error", title: "string"? }
class AlertWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const AlertWidget({required this.component, super.key});

  @override
  Widget build(BuildContext context) {
    final message = component['message']?.toString() ?? '';
    final title = component['title']?.toString();
    final variant = component['variant']?.toString() ?? 'info';
    final style = _variantStyle(variant);

    return Semantics(
      liveRegion: true,
      label: title != null && title.isNotEmpty ? '$title: $message' : message,
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: style.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.foreground, size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: style.foreground,
                      ),
                    ),
                  ),
                Text(message, style: TextStyle(color: style.foreground)),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant styling
// ---------------------------------------------------------------------------

class _AlertStyle {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  const _AlertStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });
}

_AlertStyle _variantStyle(String variant) {
  switch (variant) {
    case 'success':
      return _AlertStyle(
        background: Colors.green.shade50,
        border: Colors.green.shade200,
        foreground: Colors.green.shade800,
        icon: Icons.check_circle,
      );
    case 'warning':
      return _AlertStyle(
        background: Colors.orange.shade50,
        border: Colors.orange.shade200,
        foreground: Colors.orange.shade900,
        icon: Icons.warning,
      );
    case 'error':
      return _AlertStyle(
        background: Colors.red.shade50,
        border: Colors.red.shade200,
        foreground: Colors.red.shade800,
        icon: Icons.error,
      );
    case 'info':
    default:
      return _AlertStyle(
        background: Colors.blue.shade50,
        border: Colors.blue.shade200,
        foreground: Colors.blue.shade800,
        icon: Icons.info,
      );
  }
}
