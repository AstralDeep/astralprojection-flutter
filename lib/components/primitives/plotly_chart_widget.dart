import 'package:flutter/material.dart';

/// Renders a Plotly chart placeholder.
///
/// Schema: { type: "plotly_chart", title: "Complex Viz", data: [Plotly traces], layout: {}, config: {} }
///
/// Full WebView-based Plotly rendering is deferred for a future release.
/// For MVP, this displays a styled placeholder indicating the chart title
/// and that a browser/WebView is required.
class PlotlyChartWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const PlotlyChartWidget({
    required this.component,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final title = component['title']?.toString() ?? 'Plotly Chart';
    final traceCount = (component['data'] as List<dynamic>?)?.length ?? 0;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Plotly chart \u2013 view in browser',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (traceCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '$traceCount trace${traceCount == 1 ? '' : 's'} available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
