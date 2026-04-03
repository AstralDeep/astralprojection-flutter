// T019 — DynamicRenderer unit tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:astral/components/dynamic_renderer.dart';
import 'package:astral/state/web_socket_provider.dart';

void main() {
  group('primitiveMap', () {
    test('contains exactly 23 entries', () {
      expect(primitiveMap.length, 23);
    });

    test('contains all expected component types', () {
      const expectedTypes = [
        'container',
        'text',
        'button',
        'input',
        'card',
        'table',
        'list',
        'alert',
        'progress',
        'metric',
        'code',
        'image',
        'grid',
        'tabs',
        'divider',
        'collapsible',
        'bar_chart',
        'line_chart',
        'pie_chart',
        'plotly_chart',
        'color_picker',
        'file_upload',
        'file_download',
      ];

      for (final type in expectedTypes) {
        expect(primitiveMap.containsKey(type), isTrue,
            reason: 'Missing primitive type: $type');
      }
    });
  });

  group('supportedCapabilities', () {
    test('returns a list of all primitive map keys', () {
      final caps = supportedCapabilities;
      expect(caps, isA<List<String>>());
      expect(caps.length, 23);
      expect(caps, containsAll(primitiveMap.keys));
    });

    test('returns a new list instance each time', () {
      final a = supportedCapabilities;
      final b = supportedCapabilities;
      expect(identical(a, b), isFalse);
    });
  });

  group('DynamicRenderer', () {
    testWidgets('renders PlaceholderWidget for unknown component type',
        (tester) async {
      final wsProvider = WebSocketProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WebSocketProvider>.value(
            value: wsProvider,
            child: Scaffold(
              body: DynamicRenderer(
                component: {
                  'type': 'totally_unknown_widget',
                  'id': 'test-id-1',
                },
              ),
            ),
          ),
        ),
      );

      // PlaceholderWidget displays the unknown type name
      expect(find.textContaining('Unknown component'), findsOneWidget);
      expect(find.textContaining('totally_unknown_widget'), findsOneWidget);

      wsProvider.dispose();
    });

    testWidgets('renders PlaceholderWidget when type is empty string',
        (tester) async {
      final wsProvider = WebSocketProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<WebSocketProvider>.value(
            value: wsProvider,
            child: Scaffold(
              body: DynamicRenderer(
                component: {'id': 'no-type'},
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Unknown component'), findsOneWidget);

      wsProvider.dispose();
    });

    testWidgets('renderChildren returns SizedBox.shrink for empty list',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicRenderer.renderChildren([]),
          ),
        ),
      );

      // SizedBox.shrink renders but is zero-size
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
