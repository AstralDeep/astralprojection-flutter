import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
        padding: const EdgeInsets.all(14.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: style.tint,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: style.border, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: style.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Icon(style.icon, color: style.iconColor, size: 18.0),
            ),
            const SizedBox(width: 12.0),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 14.0,
                          color: style.iconColor,
                        ),
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      color: AstralColors.text.withValues(alpha: 0.85),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
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
  /// Tinted background fill
  final Color tint;

  /// Subtle border
  final Color border;

  /// Icon & title accent color
  final Color iconColor;

  final IconData icon;

  const _AlertStyle({
    required this.tint,
    required this.border,
    required this.iconColor,
    required this.icon,
  });
}

_AlertStyle _variantStyle(String variant) {
  switch (variant) {
    case 'success':
      const green = Color(0xFF22C55E);
      return _AlertStyle(
        tint: green.withValues(alpha: 0.08),
        border: green.withValues(alpha: 0.20),
        iconColor: green,
        icon: Icons.check_circle_rounded,
      );
    case 'warning':
      const amber = Color(0xFFF59E0B);
      return _AlertStyle(
        tint: amber.withValues(alpha: 0.08),
        border: amber.withValues(alpha: 0.20),
        iconColor: amber,
        icon: Icons.warning_rounded,
      );
    case 'error':
      return _AlertStyle(
        tint: AstralColors.error.withValues(alpha: 0.08),
        border: AstralColors.error.withValues(alpha: 0.20),
        iconColor: AstralColors.error,
        icon: Icons.error_rounded,
      );
    case 'info':
    default:
      return _AlertStyle(
        tint: AstralColors.accent.withValues(alpha: 0.08),
        border: AstralColors.accent.withValues(alpha: 0.20),
        iconColor: AstralColors.accent,
        icon: Icons.info_rounded,
      );
  }
}
