import 'package:flutter/material.dart';

/// Renders a metric card from SDUI schema.
///
/// Schema: { type: "metric", title: "Revenue", value: "$1.2M",
///   subtitle: "Q4 2025"?, icon: "trending_up"?, variant: "default",
///   progress: 0.8? }
class MetricWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const MetricWidget({required this.component, super.key});

  @override
  Widget build(BuildContext context) {
    final title = component['title']?.toString() ?? '';
    final value = component['value']?.toString() ?? '';
    final subtitle = component['subtitle']?.toString();
    final iconName = component['icon']?.toString();
    final progress = _parseProgress(component['progress']);

    final theme = Theme.of(context);
    final icon = iconName != null ? _mapIcon(iconName) : null;

    return Semantics(
      label: '$title: $value',
      child: Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with optional icon
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20.0,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8.0),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            // Large value
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            // Optional subtitle
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // Optional progress bar
            if (progress != null) ...[
              const SizedBox(height: 12.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6.0,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  static double? _parseProgress(dynamic raw) {
    if (raw == null) return null;
    double v = 0.0;
    if (raw is num) {
      v = raw.toDouble();
    } else if (raw is String) {
      v = double.tryParse(raw) ?? 0.0;
    }
    return v.clamp(0.0, 1.0);
  }
}

// ---------------------------------------------------------------------------
// Icon name -> IconData mapping
// ---------------------------------------------------------------------------

/// Maps common icon name strings to Material Icons constants.
IconData _mapIcon(String name) {
  const iconMap = <String, IconData>{
    'trending_up': Icons.trending_up,
    'trending_down': Icons.trending_down,
    'trending_flat': Icons.trending_flat,
    'attach_money': Icons.attach_money,
    'money': Icons.money,
    'people': Icons.people,
    'person': Icons.person,
    'shopping_cart': Icons.shopping_cart,
    'inventory': Icons.inventory,
    'analytics': Icons.analytics,
    'bar_chart': Icons.bar_chart,
    'pie_chart': Icons.pie_chart,
    'show_chart': Icons.show_chart,
    'timeline': Icons.timeline,
    'speed': Icons.speed,
    'timer': Icons.timer,
    'calendar_today': Icons.calendar_today,
    'schedule': Icons.schedule,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'thumb_up': Icons.thumb_up,
    'check_circle': Icons.check_circle,
    'warning': Icons.warning,
    'error': Icons.error,
    'info': Icons.info,
    'visibility': Icons.visibility,
    'cloud': Icons.cloud,
    'storage': Icons.storage,
    'memory': Icons.memory,
    'download': Icons.download,
    'upload': Icons.upload,
    'email': Icons.email,
    'notifications': Icons.notifications,
    'settings': Icons.settings,
    'home': Icons.home,
    'school': Icons.school,
    'work': Icons.work,
    'build': Icons.build,
    'bolt': Icons.bolt,
    'insights': Icons.insights,
  };
  return iconMap[name] ?? Icons.circle;
}
