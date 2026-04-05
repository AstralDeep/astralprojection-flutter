// T052 -- Apple Watch renderer tests
//
// Verifies that WatchRenderer correctly renders supported component types,
// degrades charts to metric widgets, degrades tables to list widgets, and
// silently skips unsupported component types.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/platform/watch/watch_renderer.dart';
import 'package:astral/components/primitives/text_widget.dart';
import 'package:astral/components/primitives/metric_widget.dart';
import 'package:astral/components/primitives/alert_widget.dart';
import 'package:astral/components/primitives/card_widget.dart';
import 'package:astral/components/primitives/button_widget.dart';
import 'package:astral/components/primitives/list_widget.dart';
import 'package:astral/components/primitives/progress_widget.dart';
import 'package:astral/components/primitives/divider_widget.dart';
import 'package:astral/components/primitives/container_widget.dart';

/// No-op event handler for tests.
void _noopSendEvent(String action, Map<String, dynamic> payload) {}

/// Helper to pump a WatchRenderer with given components.
Widget _buildWatchRenderer(List<Map<String, dynamic>> components) {
  return MaterialApp(
    home: Scaffold(
      body: WatchRenderer(
        components: components,
        sendEvent: _noopSendEvent,
      ),
    ),
  );
}

void main() {
  group('T052 — Chart degradation to metric widget', () {
    for (final chartType in ['bar_chart', 'line_chart', 'pie_chart', 'plotly_chart']) {
      testWidgets('$chartType degrades to MetricWidget', (tester) async {
        await tester.pumpWidget(_buildWatchRenderer([
          {
            'type': chartType,
            'title': 'Test $chartType',
            'datasets': [
              {
                'label': 'Series 1',
                'data': [42, 58, 73],
              }
            ],
          }
        ]));
        await tester.pumpAndSettle();

        // Should render a MetricWidget, not the original chart
        expect(find.byType(MetricWidget), findsOneWidget);
        // The title should be preserved
        expect(find.text('Test $chartType'), findsOneWidget);
        // The first data value should be displayed
        expect(find.text('42'), findsOneWidget);
      });
    }

    testWidgets('chart without datasets shows fallback metric', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {
          'type': 'bar_chart',
          'title': 'Empty Chart',
        }
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.text('Empty Chart'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
    });
  });

  group('T052 — Table degradation to list widget', () {
    testWidgets('table degrades to ListWidget with first column values',
        (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {
          'type': 'table',
          'headers': ['Name', 'Score', 'Grade'],
          'rows': [
            ['Alice', '95', 'A'],
            ['Bob', '87', 'B+'],
            ['Carol', '72', 'C'],
          ],
        }
      ]));
      await tester.pumpAndSettle();

      // Should render a ListWidget, not a TableWidget
      expect(find.byType(ListWidget), findsOneWidget);
      // First column values should appear
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });

    testWidgets('table with empty rows degrades to empty list',
        (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {
          'type': 'table',
          'headers': ['Name'],
          'rows': [],
        }
      ]));
      await tester.pumpAndSettle();

      // Should render a ListWidget with no items
      expect(find.byType(ListWidget), findsOneWidget);
    });
  });

  group('T052 — Unsupported types silently skipped', () {
    testWidgets('unknown component type is not rendered', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'html_view', 'content': '<p>Hello</p>'},
        {'type': 'code_editor', 'code': 'print("hi")'},
        {'type': 'file_upload', 'label': 'Upload'},
      ]));
      await tester.pumpAndSettle();

      // None of the unsupported types should render any visible widget
      // The WatchRenderer should show an empty SizedBox.shrink
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('mix of supported and unsupported renders only supported',
        (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'text', 'content': 'Hello Watch'},
        {'type': 'html_view', 'content': '<p>Skipped</p>'},
        {'type': 'metric', 'title': 'Score', 'value': '99'},
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(TextWidget), findsOneWidget);
      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.text('Hello Watch'), findsOneWidget);
      expect(find.text('99'), findsOneWidget);
    });
  });

  group('T052 — Supported types render correctly', () {
    testWidgets('text component renders TextWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'text', 'content': 'Watch text'},
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(TextWidget), findsOneWidget);
      expect(find.text('Watch text'), findsOneWidget);
    });

    testWidgets('metric component renders MetricWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'metric', 'title': 'Steps', 'value': '10,000'},
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(MetricWidget), findsOneWidget);
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('10,000'), findsOneWidget);
    });

    testWidgets('alert component renders AlertWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'alert', 'message': 'Low battery', 'variant': 'warning'},
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(AlertWidget), findsOneWidget);
    });

    testWidgets('card component renders CardWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'card', 'title': 'Summary'},
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('button component renders ButtonWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'button', 'label': 'Tap Me', 'action': 'test_action'},
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(ButtonWidget), findsOneWidget);
    });

    testWidgets('list component renders ListWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {
          'type': 'list',
          'items': ['Item 1', 'Item 2'],
          'ordered': false,
        },
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(ListWidget), findsOneWidget);
    });

    testWidgets('progress component renders ProgressWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'progress', 'value': 0.75, 'label': 'Loading'},
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(ProgressWidget), findsOneWidget);
    });

    testWidgets('divider component renders DividerWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {'type': 'divider'},
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(DividerWidget), findsOneWidget);
    });

    testWidgets('container component renders ContainerWidget', (tester) async {
      await tester.pumpWidget(_buildWatchRenderer([
        {
          'type': 'container',
          'children': [
            {'type': 'text', 'content': 'Inside container'},
          ],
        },
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(ContainerWidget), findsOneWidget);
    });
  });
}
