// T021 — AgentPermissionsSheet widget tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:astral/components/agents/agent_permissions_sheet.dart';
import 'package:astral/state/web_socket_provider.dart';

/// Minimal mock WebSocketProvider that avoids real WebSocket connections.
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

  @override
  List<Map<String, dynamic>>? get savedComponents => null;

  final List<Map<String, dynamic>> sentEvents = [];

  @override
  void sendEvent(String action, Map<String, dynamic> payload) {
    sentEvents.add({'action': action, 'payload': payload});
  }
}

void main() {
  late _MockWebSocketProvider mockWs;

  setUp(() {
    mockWs = _MockWebSocketProvider();
  });

  Widget buildSheet({
    String agentId = 'agent-1',
    String agentName = 'Test Agent',
    Map<String, dynamic> initialPermissions = const {},
  }) {
    return ChangeNotifierProvider<WebSocketProvider>.value(
      value: mockWs,
      child: MaterialApp(
        home: Scaffold(
          body: AgentPermissionsSheet(
            agentId: agentId,
            agentName: agentName,
            initialPermissions: initialPermissions,
          ),
        ),
      ),
    );
  }

  group('AgentPermissionsSheet (T021)', () {
    testWidgets('renders 4 scope cards with labels', (tester) async {
      await tester.pumpWidget(buildSheet());

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Write'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('displays agent name in header', (tester) async {
      await tester.pumpWidget(buildSheet(agentName: 'My Custom Agent'));

      expect(find.text('My Custom Agent'), findsOneWidget);
    });

    testWidgets('displays Agent Permissions title', (tester) async {
      await tester.pumpWidget(buildSheet());

      expect(find.text('Agent Permissions'), findsOneWidget);
    });

    testWidgets('scope cards have Switch widgets', (tester) async {
      await tester.pumpWidget(buildSheet());

      // There should be 4 scope switches
      expect(find.byType(Switch), findsNWidgets(4));
    });

    testWidgets('toggling a scope switch shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(buildSheet());

      // Tap the first Switch to toggle it
      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // A confirmation dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('cancel on confirmation dialog dismisses it', (tester) async {
      await tester.pumpWidget(buildSheet());

      // Toggle a scope switch
      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('confirm on dialog sends permission update via WebSocket',
        (tester) async {
      await tester.pumpWidget(buildSheet(agentId: 'agent-42'));

      // Toggle a scope switch
      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Confirm the dialog
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Verify a sendEvent was called
      expect(mockWs.sentEvents, isNotEmpty);
      expect(mockWs.sentEvents.last['action'], 'update_agent_permissions');
    });

    testWidgets('renders with initial permissions that include tools',
        (tester) async {
      await tester.pumpWidget(buildSheet(
        initialPermissions: {
          'scopes': {
            'tools:read': true,
            'tools:write': false,
            'tools:search': true,
            'tools:system': false,
          },
          'tools': [
            {'scope': 'tools:read', 'name': 'read_file', 'enabled': true},
            {'scope': 'tools:read', 'name': 'list_dir', 'enabled': false},
          ],
        },
      ));

      // Should render without error
      expect(find.text('Agent Permissions'), findsOneWidget);
    });
  });
}
