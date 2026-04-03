import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null && label.isNotEmpty || showPercentage)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (label != null && label.isNotEmpty)
                    Flexible(
                      child: Text(label, style: theme.textTheme.bodyMedium),
                    ),
                  if (showPercentage)
                    Text(
                      '${(value * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8.0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
