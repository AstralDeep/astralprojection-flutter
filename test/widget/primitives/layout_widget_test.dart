import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:astral/components/primitives/container_widget.dart';
import 'package:astral/components/primitives/grid_widget.dart';
import 'package:astral/components/primitives/tabs_widget.dart';
import 'package:astral/components/primitives/collapsible_widget.dart';
import 'package:astral/components/primitives/divider_widget.dart';
import 'package:astral/state/web_socket_provider.dart';

void main() {
  void noOpSendEvent(String action, Map<String, dynamic> payload) {}

  /// Wraps widget in MaterialApp with a WebSocketProvider for DynamicRenderer.
  Widget wrapWithProvider(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => WebSocketProvider(),
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('ContainerWidget', () {
    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(wrapWithProvider(
        ContainerWidget(
          component: {
            'type': 'container',
            'children': [
              {'type': 'text', 'content': 'Inside container'},
            ],
          },
          sendEvent: noOpSendEvent,
        ),
      ));
      expect(find.text('Inside container'), findsOneWidget);
    });
  });

  group('GridWidget', () {
    testWidgets('renders with specified columns', (tester) async {
      await tester.pumpWidget(wrapWithProvider(
        GridWidget(
          component: {
            'type': 'grid',
            'columns': 3,
            'children': [
              {'type': 'text', 'content': 'Cell 1'},
              {'type': 'text', 'content': 'Cell 2'},
              {'type': 'text', 'content': 'Cell 3'},
            ],
          },
          sendEvent: noOpSendEvent,
        ),
      ));
      expect(find.text('Cell 1'), findsOneWidget);
      expect(find.text('Cell 2'), findsOneWidget);
      expect(find.text('Cell 3'), findsOneWidget);
    });
  });

  group('TabsWidget', () {
    testWidgets('renders tab labels', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => WebSocketProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: TabsWidget(
                component: {
                  'type': 'tabs',
                  'tabs': [
                    {'label': 'Tab A', 'content': []},
                    {'label': 'Tab B', 'content': []},
                  ],
                },
                sendEvent: noOpSendEvent,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
    });
  });

  group('CollapsibleWidget', () {
    testWidgets('respects default_open true', (tester) async {
      await tester.pumpWidget(wrapWithProvider(
        CollapsibleWidget(
          component: {
            'type': 'collapsible',
            'title': 'Details',
            'default_open': true,
            'content': [
              {'type': 'text', 'content': 'Hidden content'},
            ],
          },
          sendEvent: noOpSendEvent,
        ),
      ));
      expect(find.text('Details'), findsOneWidget);
      // Content should be visible when default_open is true
      expect(find.text('Hidden content'), findsOneWidget);
    });

    testWidgets('respects default_open false', (tester) async {
      await tester.pumpWidget(wrapWithProvider(
        CollapsibleWidget(
          component: {
            'type': 'collapsible',
            'title': 'Collapsed',
            'default_open': false,
            'content': [
              {'type': 'text', 'content': 'Should be hidden'},
            ],
          },
          sendEvent: noOpSendEvent,
        ),
      ));
      expect(find.text('Collapsed'), findsOneWidget);
      // Content should not be visible initially
      expect(find.text('Should be hidden'), findsNothing);
    });
  });

  group('DividerWidget', () {
    testWidgets('renders divider', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DividerWidget(component: {'type': 'divider'}),
        ),
      ));
      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
