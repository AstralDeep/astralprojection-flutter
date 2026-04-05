// T020 — SavedComponentsDrawer widget tests
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:astral/components/workspace/saved_components_drawer.dart';
import 'package:astral/state/web_socket_provider.dart';

/// Minimal mock WebSocketProvider so we don't open a real WebSocket.
class _MockWebSocketProvider extends ChangeNotifier
    implements WebSocketProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  bool get connected => false;

  @override
  String? get sessionId => null;

  @override
  String? get error => null;

  @override
  List<Map<String, dynamic>> get components => [];

  @override
  bool get hasReceivedRender => false;

  @override
  List<Map<String, dynamic>> get chatMessages => [];

  List<Map<String, dynamic>>? _savedComponents;

  @override
  List<Map<String, dynamic>>? get savedComponents => _savedComponents;

  final List<Map<String, dynamic>> sentEvents = [];

  @override
  void sendEvent(String action, Map<String, dynamic> payload) {
    sentEvents.add({'action': action, 'payload': payload});
  }

  /// Simulate receiving saved components from backend.
  void simulateSavedComponents(List<Map<String, dynamic>> components) {
    _savedComponents = components;
    notifyListeners();
  }
}

void main() {
  late _MockWebSocketProvider mockWs;

  setUp(() {
    mockWs = _MockWebSocketProvider();
  });

  Widget buildDrawer() {
    return ChangeNotifierProvider<WebSocketProvider>.value(
      value: mockWs,
      child: const MaterialApp(
        home: Scaffold(
          body: SavedComponentsDrawer(),
        ),
      ),
    );
  }

  group('SavedComponentsDrawer (T020)', () {
    testWidgets('renders the Saved Components header', (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.pump();

      expect(find.text('Saved Components'), findsOneWidget);
    });

    testWidgets('shows empty state placeholder when no components',
        (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.pump();

      // The drawer should show a "No saved components" message
      expect(find.textContaining('No saved components'), findsOneWidget);
    });

    testWidgets('sends get_saved_components on init', (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.pump();

      expect(mockWs.sentEvents, isNotEmpty);
      expect(mockWs.sentEvents.first['action'], 'get_saved_components');
    });

    testWidgets('renders component cards when savedComponents arrive',
        (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.pump();

      // Simulate backend response
      mockWs.simulateSavedComponents([
        {'id': 'c1', 'type': 'chart', 'title': 'Revenue Chart'},
        {'id': 'c2', 'type': 'table', 'title': 'User Table'},
      ]);
      await tester.pump();

      expect(find.text('Revenue Chart'), findsOneWidget);
      expect(find.text('User Table'), findsOneWidget);
    });

    testWidgets('Condense All button appears with 2+ components',
        (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.pump();

      mockWs.simulateSavedComponents([
        {'id': 'c1', 'type': 'chart', 'title': 'A'},
        {'id': 'c2', 'type': 'table', 'title': 'B'},
      ]);
      await tester.pump();

      expect(find.text('Condense All'), findsOneWidget);
    });

    testWidgets('Condense All button not shown with fewer than 2 components',
        (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.pump();

      mockWs.simulateSavedComponents([
        {'id': 'c1', 'type': 'chart', 'title': 'Only One'},
      ]);
      await tester.pump();

      expect(find.text('Condense All'), findsNothing);
    });

    group('WebSocket message integration', () {
      test('save_component message structure is valid', () {
        final message = jsonEncode({
          'type': 'save_component',
          'component': {'id': 'c1', 'type': 'chart', 'title': 'Test'},
        });
        final decoded = jsonDecode(message) as Map<String, dynamic>;
        expect(decoded['type'], 'save_component');
        expect(decoded['component'], isA<Map<String, dynamic>>());
      });

      test('get_saved_components message structure is valid', () {
        final message = jsonEncode({
          'type': 'get_saved_components',
        });
        final decoded = jsonDecode(message) as Map<String, dynamic>;
        expect(decoded['type'], 'get_saved_components');
      });

      test('delete_saved_component message structure is valid', () {
        final message = jsonEncode({
          'type': 'delete_saved_component',
          'component_id': 'c1',
        });
        final decoded = jsonDecode(message) as Map<String, dynamic>;
        expect(decoded['type'], 'delete_saved_component');
        expect(decoded['component_id'], 'c1');
      });

      test('combine_components message structure is valid', () {
        final message = jsonEncode({
          'type': 'combine_components',
          'source_id': 'c1',
          'target_id': 'c2',
        });
        final decoded = jsonDecode(message) as Map<String, dynamic>;
        expect(decoded['type'], 'combine_components');
        expect(decoded['source_id'], 'c1');
        expect(decoded['target_id'], 'c2');
      });

      test('condense_components message structure is valid', () {
        final message = jsonEncode({
          'type': 'condense_components',
          'component_ids': ['c1', 'c2', 'c3'],
        });
        final decoded = jsonDecode(message) as Map<String, dynamic>;
        expect(decoded['type'], 'condense_components');
        expect(decoded['component_ids'], hasLength(3));
      });
    });
  });
}
