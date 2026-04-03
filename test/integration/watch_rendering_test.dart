// T081 — Integration test: watch glanceable rendering and graceful degradation
//
// Tests the full watch rendering pipeline:
// - WatchRenderer with WatchTheme in a 200px constrained viewport
// - Supported components render correctly
// - Charts degrade to metrics
// - Tables degrade to lists
// - Unsupported types are silently dropped

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:astral/platform/watch/watch_renderer.dart';
import 'package:astral/platform/watch/watch_theme.dart';
import 'package:astral/components/primitives/text_widget.dart';
import 'package:astral/components/primitives/metric_widget.dart';
import 'package:astral/components/primitives/alert_widget.dart';
import 'package:astral/components/primitives/list_widget.dart';

void _noop(String action, Map<String, dynamic> payload) {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('T081 — Watch glanceable rendering integration', () {
    testWidgets(
      'renders supported components in watch-sized viewport with WatchTheme',
      skip: true, // Requires watch simulator
      (WidgetTester tester) async {
        final components = <Map<String, dynamic>>[
          {'type': 'text', 'content': 'Welcome'},
          {'type': 'metric', 'title': 'Heart Rate', 'value': '72 bpm'},
          {'type': 'alert', 'message': 'Goal reached!', 'variant': 'success'},
          {'type': 'button', 'label': 'Refresh', 'action': 'refresh'},
          {'type': 'progress', 'value': 0.75},
          {'type': 'divider'},
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: WatchTheme.theme,
            home: SizedBox(
              width: WatchTheme.maxViewportWidth,
              height: 250,
              child: Scaffold(
                body: Padding(
                  padding: WatchTheme.contentPadding,
                  child: WatchRenderer(
                    components: components,
                    sendEvent: _noop,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify supported components rendered
        expect(find.byType(TextWidget), findsOneWidget);
        expect(find.byType(MetricWidget), findsOneWidget);
        expect(find.byType(AlertWidget), findsOneWidget);
        expect(find.text('Welcome'), findsOneWidget);
        expect(find.text('72 bpm'), findsOneWidget);
        expect(find.text('Goal reached!'), findsOneWidget);
      },
    );

    testWidgets(
      'gracefully degrades charts to metrics in watch viewport',
      skip: true, // Requires watch simulator
      (WidgetTester tester) async {
        final components = <Map<String, dynamic>>[
          {
            'type': 'bar_chart',
            'title': 'Daily Steps',
            'labels': ['Mon', 'Tue', 'Wed'],
            'datasets': [
              {'label': 'Steps', 'data': [8000, 10000, 7500], 'color': '#00ff00'},
            ],
          },
          {
            'type': 'line_chart',
            'title': 'Weight Trend',
            'labels': ['W1', 'W2'],
            'datasets': [
              {'label': 'kg', 'data': [75.2, 74.8], 'color': '#0000ff'},
            ],
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: WatchTheme.theme,
            home: SizedBox(
              width: WatchTheme.maxViewportWidth,
              height: 250,
              child: Scaffold(
                body: WatchRenderer(
                  components: components,
                  sendEvent: _noop,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Both charts should degrade to MetricWidgets
        expect(find.byType(MetricWidget), findsNWidgets(2));
        expect(find.text('Daily Steps'), findsOneWidget);
        expect(find.text('8000'), findsOneWidget);
        expect(find.text('Weight Trend'), findsOneWidget);
        expect(find.text('75.2'), findsOneWidget);
      },
    );

    testWidgets(
      'gracefully degrades tables to lists in watch viewport',
      skip: true, // Requires watch simulator
      (WidgetTester tester) async {
        final components = <Map<String, dynamic>>[
          {
            'type': 'table',
            'headers': ['Student', 'Grade'],
            'rows': [
              ['Alice', 'A'],
              ['Bob', 'B+'],
              ['Carol', 'A-'],
            ],
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: WatchTheme.theme,
            home: SizedBox(
              width: WatchTheme.maxViewportWidth,
              height: 250,
              child: Scaffold(
                body: WatchRenderer(
                  components: components,
                  sendEvent: _noop,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Table should degrade to ListWidget with first-column values
        expect(find.byType(ListWidget), findsOneWidget);
        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
        expect(find.text('Carol'), findsOneWidget);
      },
    );

    testWidgets(
      'silently drops unsupported types without errors',
      skip: true, // Requires watch simulator
      (WidgetTester tester) async {
        final components = <Map<String, dynamic>>[
          {'type': 'text', 'content': 'Visible'},
          {'type': 'code', 'content': 'print("hidden")'},
          {'type': 'image', 'src': 'https://example.com/photo.jpg'},
          {'type': 'tabs', 'tabs': []},
          {'type': 'grid', 'columns': 3, 'children': []},
          {'type': 'collapsible', 'title': 'Hidden', 'children': []},
          {'type': 'metric', 'title': 'Also Visible', 'value': '99'},
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: WatchTheme.theme,
            home: SizedBox(
              width: WatchTheme.maxViewportWidth,
              height: 250,
              child: Scaffold(
                body: WatchRenderer(
                  components: components,
                  sendEvent: _noop,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Only supported types rendered
        expect(find.byType(TextWidget), findsOneWidget);
        expect(find.byType(MetricWidget), findsOneWidget);
        expect(find.text('Visible'), findsOneWidget);
        expect(find.text('Also Visible'), findsOneWidget);
        // Unsupported content should not appear
        expect(find.text('print("hidden")'), findsNothing);
        expect(find.text('Hidden'), findsNothing);
      },
    );
  });
}
