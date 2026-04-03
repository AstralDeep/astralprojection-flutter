// T075 — Widget test: WatchRenderer filters and degrades components
//
// Verifies that:
// - Supported types (text, metric, alert, card, button, list, progress,
//   divider, container) are rendered
// - Charts are degraded to MetricWidget (title + first data value)
// - Tables are degraded to ListWidget (first column as items)
// - Unsupported types (code, image, grid, tabs, collapsible, etc.) are skipped

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:astral/platform/watch/watch_renderer.dart';
import 'package:astral/state/device_profile_provider.dart';
import 'package:astral/components/primitives/text_widget.dart';
import 'package:astral/components/primitives/metric_widget.dart';
import 'package:astral/components/primitives/alert_widget.dart';
import 'package:astral/components/primitives/button_widget.dart';
import 'package:astral/components/primitives/list_widget.dart';
import 'package:astral/components/primitives/progress_widget.dart';
import 'package:astral/components/primitives/divider_widget.dart';

void _noop(String action, Map<String, dynamic> payload) {}

Widget _wrap(List<Map<String, dynamic>> components) {
  return ChangeNotifierProvider(
    create: (_) => DeviceProfileProvider(),
    child: MaterialApp(
      home: Scaffold(
        body: WatchRenderer(components: components, sendEvent: _noop),
      ),
    ),
  );
}

void main() {
  group('T075 — WatchRenderer component filtering', () {
    testWidgets('renders text component', (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'text', 'content': 'Hello Watch'},
      ]));
      expect(find.byType(TextWidget), findsOneWidget);
    });

    testWidgets('renders metric component', (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'metric', 'title': 'Steps', 'value': '10000'},
      ]));
      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.text('10000'), findsOneWidget);
    });

    testWidgets('renders alert component', (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'alert', 'message': 'Watch alert', 'variant': 'info'},
      ]));
      expect(find.byType(AlertWidget), findsOneWidget);
      expect(find.text('Watch alert'), findsOneWidget);
    });

    testWidgets('renders button component', (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'button', 'label': 'Tap me', 'action': 'tap'},
      ]));
      expect(find.byType(ButtonWidget), findsOneWidget);
    });

    testWidgets('renders list component', (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'list', 'items': ['a', 'b', 'c']},
      ]));
      expect(find.byType(ListWidget), findsOneWidget);
    });

    testWidgets('renders progress component', (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'progress', 'value': 0.5},
      ]));
      expect(find.byType(ProgressWidget), findsOneWidget);
    });

    testWidgets('renders divider component', (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'divider'},
      ]));
      expect(find.byType(DividerWidget), findsOneWidget);
    });

    testWidgets('degrades bar_chart to MetricWidget', (tester) async {
      await tester.pumpWidget(_wrap([
        {
          'type': 'bar_chart',
          'title': 'Monthly Sales',
          'labels': ['Jan', 'Feb'],
          'datasets': [
            {'label': '2025', 'data': [100, 200], 'color': '#4285f4'},
          ],
        },
      ]));
      // Should render as MetricWidget, not a chart
      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.text('Monthly Sales'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('degrades line_chart to MetricWidget', (tester) async {
      await tester.pumpWidget(_wrap([
        {
          'type': 'line_chart',
          'title': 'Trend',
          'labels': ['Q1'],
          'datasets': [
            {'label': 'Rev', 'data': [42], 'color': '#ff0000'},
          ],
        },
      ]));
      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.text('Trend'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('degrades pie_chart to MetricWidget', (tester) async {
      await tester.pumpWidget(_wrap([
        {
          'type': 'pie_chart',
          'title': 'Share',
          'datasets': [
            {'label': 'A', 'data': [55], 'color': '#00ff00'},
          ],
        },
      ]));
      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
    });

    testWidgets('degrades table to ListWidget', (tester) async {
      await tester.pumpWidget(_wrap([
        {
          'type': 'table',
          'headers': ['Name', 'Score'],
          'rows': [
            ['Alice', '95'],
            ['Bob', '87'],
            ['Carol', '92'],
          ],
        },
      ]));
      // Should render as ListWidget with first column values
      expect(find.byType(ListWidget), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });

    testWidgets('silently skips unsupported types', (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'code', 'content': 'print("hi")'},
        {'type': 'image', 'src': 'https://example.com/img.png'},
        {'type': 'grid', 'columns': 2, 'children': []},
        {'type': 'tabs', 'tabs': []},
        {'type': 'collapsible', 'title': 'Expand', 'children': []},
        {'type': 'color_picker', 'value': '#fff'},
        {'type': 'file_upload'},
        {'type': 'file_download'},
      ]));

      // None of these should produce any visible widget
      expect(find.byType(SizedBox), findsOneWidget); // SizedBox.shrink()
    });

    testWidgets('renders mixed supported and unsupported components',
        (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'text', 'content': 'Header'},
        {'type': 'code', 'content': 'should be skipped'},
        {'type': 'metric', 'title': 'CPU', 'value': '42%'},
        {'type': 'image', 'src': 'skip.png'},
        {'type': 'alert', 'message': 'OK', 'variant': 'success'},
      ]));

      expect(find.byType(TextWidget), findsOneWidget);
      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.byType(AlertWidget), findsOneWidget);
      // code and image should not appear
      expect(find.text('should be skipped'), findsNothing);
    });

    testWidgets('degrades chart with no datasets to metric showing "--"',
        (tester) async {
      await tester.pumpWidget(_wrap([
        {'type': 'bar_chart', 'title': 'Empty Chart', 'datasets': []},
      ]));
      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
    });
  });
}
