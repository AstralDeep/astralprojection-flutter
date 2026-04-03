import 'package:flutter/material.dart';
import '../../components/primitives/text_widget.dart';
import '../../components/primitives/metric_widget.dart';
import '../../components/primitives/alert_widget.dart';
import '../../components/primitives/card_widget.dart';
import '../../components/primitives/button_widget.dart';
import '../../components/primitives/list_widget.dart';
import '../../components/primitives/progress_widget.dart';
import '../../components/primitives/divider_widget.dart';
import '../../components/primitives/container_widget.dart';

/// Component types that render natively on watch.
const Set<String> watchSupportedTypes = {
  'text',
  'metric',
  'alert',
  'card',
  'button',
  'list',
  'progress',
  'divider',
  'container',
};

/// Component types that can be degraded to a simpler watch-compatible widget.
const Set<String> watchDegradableTypes = {
  'bar_chart',
  'line_chart',
  'pie_chart',
  'plotly_chart',
  'table',
};

/// Renders SDUI components filtered and degraded for Apple Watch glanceable UI.
///
/// Supported types are rendered directly. Charts are degraded to metric widgets
/// (extracting title and first data value). Tables are degraded to list widgets
/// (extracting the first column as items). All other types are silently skipped.
class WatchRenderer extends StatelessWidget {
  final List<Map<String, dynamic>> components;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const WatchRenderer({
    required this.components,
    required this.sendEvent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = <Widget>[];
    for (final component in components) {
      final widget = _renderComponent(component);
      if (widget != null) {
        filtered.add(widget);
      }
    }

    if (filtered.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: filtered,
      ),
    );
  }

  /// Render a single component, degrading or skipping as needed.
  Widget? _renderComponent(Map<String, dynamic> component) {
    final type = component['type'] as String? ?? '';

    // Direct watch-supported types
    if (watchSupportedTypes.contains(type)) {
      return _buildSupported(type, component);
    }

    // Chart types -> degrade to metric
    if (_isChartType(type)) {
      return _degradeChartToMetric(component);
    }

    // Table -> degrade to list
    if (type == 'table') {
      return _degradeTableToList(component);
    }

    // All other types are silently skipped
    return null;
  }

  bool _isChartType(String type) {
    return type == 'bar_chart' ||
        type == 'line_chart' ||
        type == 'pie_chart' ||
        type == 'plotly_chart';
  }

  Widget? _buildSupported(String type, Map<String, dynamic> component) {
    switch (type) {
      case 'text':
        return TextWidget(component: component);
      case 'metric':
        return MetricWidget(component: component);
      case 'alert':
        return AlertWidget(component: component);
      case 'card':
        return CardWidget(component: component, sendEvent: sendEvent);
      case 'button':
        return ButtonWidget(component: component, sendEvent: sendEvent);
      case 'list':
        return ListWidget(component: component);
      case 'progress':
        return ProgressWidget(component: component);
      case 'divider':
        return DividerWidget(component: component);
      case 'container':
        return ContainerWidget(component: component, sendEvent: sendEvent);
      default:
        return null;
    }
  }

  /// Degrade a chart component to a MetricWidget.
  ///
  /// Extracts the chart title and the first data value from the first dataset.
  Widget _degradeChartToMetric(Map<String, dynamic> component) {
    final title = component['title']?.toString() ?? 'Chart';
    final datasets = component['datasets'] as List<dynamic>? ?? [];

    String value = '--';
    if (datasets.isNotEmpty) {
      final firstDataset = datasets.first as Map<String, dynamic>? ?? {};
      final data = firstDataset['data'] as List<dynamic>? ?? [];
      if (data.isNotEmpty) {
        value = data.first.toString();
      }
    }

    return MetricWidget(component: {
      'type': 'metric',
      'title': title,
      'value': value,
      'icon': 'bar_chart',
    });
  }

  /// Degrade a table component to a ListWidget.
  ///
  /// Extracts the first column from each row as list items.
  Widget _degradeTableToList(Map<String, dynamic> component) {
    final rows = component['rows'] as List<dynamic>? ?? [];
    final items = <String>[];

    for (final row in rows) {
      if (row is List && row.isNotEmpty) {
        items.add(row.first.toString());
      }
    }

    return ListWidget(component: {
      'type': 'list',
      'items': items,
      'ordered': false,
    });
  }
}
