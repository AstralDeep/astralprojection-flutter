import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders a linear progress indicator from SDUI schema.
///
/// Schema: { type: "progress", value: 0.75, label: "Loading..."?,
///   variant: "default", show_percentage: true }
class ProgressWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const ProgressWidget({required this.component, super.key});

  @override
  Widget build(BuildContext context) {
    final value = _clampDouble(component['value']);
    final label = component['label']?.toString();
    final showPercentage = component['show_percentage'] != false;

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null && label.isNotEmpty || showPercentage)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (label != null && label.isNotEmpty)
                    Flexible(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AstralColors.text,
                        ),
                      ),
                    ),
                  if (showPercentage)
                    Text(
                      '${(value * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AstralColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8.0,
              backgroundColor: AstralColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AstralColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parse and clamp value to [0.0, 1.0].
  static double _clampDouble(dynamic raw) {
    double v = 0.0;
    if (raw is num) {
      v = raw.toDouble();
    } else if (raw is String) {
      v = double.tryParse(raw) ?? 0.0;
    }
    return v.clamp(0.0, 1.0);
  }
}
