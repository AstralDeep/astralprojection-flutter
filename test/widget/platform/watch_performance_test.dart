// T053 -- Apple Watch performance smoke test
//
// Verifies that WatchRenderer can render a dashboard with multiple
// components without errors. This is a basic smoke test since precise
// timing benchmarks are unreliable in widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/platform/watch/watch_renderer.dart';
import 'package:astral/components/primitives/metric_widget.dart';
import 'package:astral/components/primitives/text_widget.dart';
import 'package:astral/components/primitives/alert_widget.dart';
import 'package:astral/components/primitives/button_widget.dart';
import 'package:astral/components/primitives/progress_widget.dart';

/// No-op event handler for tests.
void _noopSendEvent(String action, Map<String, dynamic> payload) {}

/// Generates a realistic watch dashboard with [count] mixed components.
List<Map<String, dynamic>> _generateDashboard(int count) {
  final components = <Map<String, dynamic>>[];
  final types = [
    {'type': 'text', 'content': 'Dashboard Header'},
    {'type': 'metric', 'title': 'Heart Rate', 'value': '72 bpm', 'icon': 'favorite'},
    {'type': 'metric', 'title': 'Steps', 'value': '8,432', 'icon': 'trending_up'},
    {'type': 'alert', 'message': 'Goal almost reached!', 'variant': 'info'},
    {'type': 'progress', 'value': 0.84, 'label': 'Daily Goal'},
    {'type': 'button', 'label': 'Refresh', 'action': 'refresh'},
    {'type': 'divider'},
    {'type': 'text', 'content': 'Recent Activity'},
    {
      'type': 'list',
      'items': ['Morning run', 'Lunch walk', 'Evening yoga'],
      'ordered': false,
    },
    {'type': 'metric', 'title': 'Calories', 'value': '1,847', 'icon': 'bolt'},
  ];

  for (int i = 0; i < count; i++) {
    components.add(Map<String, dynamic>.from(types[i % types.length]));
  }
  return components;
}

void main() {
  group('T053 — Watch dashboard rendering smoke test', () {
    testWidgets('renders 10 components without errors', (tester) async {
      final components = _generateDashboard(10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchRenderer(
              components: components,
              sendEvent: _noopSendEvent,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 10 components should render (no unsupported types in our list)
      // Verify key widgets are present
      expect(find.byType(TextWidget), findsWidgets);
      expect(find.byType(MetricWidget), findsWidgets);
      expect(find.byType(AlertWidget), findsWidgets);
      expect(find.byType(ProgressWidget), findsWidgets);
      expect(find.byType(ButtonWidget), findsWidgets);

      // No errors should have been thrown during rendering
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders mixed supported and degraded components',
        (tester) async {
      final components = <Map<String, dynamic>>[
        {'type': 'text', 'content': 'Watch Dashboard'},
        {'type': 'metric', 'title': 'Score', 'value': '95'},
        {
          'type': 'bar_chart',
          'title': 'Weekly Stats',
          'datasets': [
            {'label': 'Data', 'data': [10, 20, 30]},
          ],
        },
        {
          'type': 'table',
          'headers': ['Name', 'Value'],
          'rows': [
            ['CPU', '42%'],
            ['RAM', '67%'],
          ],
        },
        {'type': 'html_view', 'content': '<p>Skipped</p>'}, // unsupported
        {'type': 'progress', 'value': 0.5, 'label': 'Loading'},
        {'type': 'alert', 'message': 'Update available', 'variant': 'info'},
        {'type': 'button', 'label': 'OK', 'action': 'confirm'},
        {'type': 'divider'},
        {'type': 'metric', 'title': 'Temp', 'value': '23C'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchRenderer(
              components: components,
              sendEvent: _noopSendEvent,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // bar_chart should degrade to MetricWidget (so 3 total metrics)
      expect(find.byType(MetricWidget), findsNWidgets(3));

      // html_view should be skipped (9 visible components total)
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty component list renders without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchRenderer(
              components: const [],
              sendEvent: _noopSendEvent,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render the shrink fallback
      expect(tester.takeException(), isNull);
    });
  });
}
