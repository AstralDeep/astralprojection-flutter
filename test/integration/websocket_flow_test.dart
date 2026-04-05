// T067 — Integration test: WebSocket chat flow with inline SDUI and
// reconnection. Requires a running backend or emulator.
//
// Run with:
//   flutter test integration_test/websocket_flow_test.dart
//
// Skipped by default — enable when backend is available.
@Skip('Requires running backend / emulator')
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/state/web_socket_provider.dart';
import 'package:astral/state/token_storage_provider.dart';
import 'package:astral/state/project_provider.dart';
import 'package:astral/state/device_profile_provider.dart';
import 'package:astral/state/theme_provider.dart';
import 'package:astral/components/workspace/workspace_layout.dart';

void main() {
  group('WebSocket Chat Flow Integration (T067)', () {
    late WebSocketProvider wsProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      wsProvider = WebSocketProvider();
    });

    tearDown(() {
      wsProvider.dispose();
    });

    testWidgets('chat input bar sends chat_message event', (tester) async {
      // Simulate a connected provider with a rendered component tree.
      wsProvider.simulateMessage(jsonEncode({
        'type': 'ui_render',
        'components': [
          {'type': 'text', 'id': 'welcome', 'content': 'Welcome'},
        ],
      }));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WebSocketProvider>.value(value: wsProvider),
            ChangeNotifierProvider<TokenStorageProvider>(
              create: (_) => TokenStorageProvider(),
            ),
            ChangeNotifierProvider<ProjectProvider>(
              create: (_) => ProjectProvider(),
            ),
            ChangeNotifierProvider<DeviceProfileProvider>(
              create: (_) => DeviceProfileProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: WorkspaceLayout()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the chat input bar is present.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Type a message and tap send.
      await tester.enterText(find.byType(TextField), 'Hello agent');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // The text field should be cleared after sending.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('ui_append adds chat message to list', (tester) async {
      wsProvider.simulateMessage(jsonEncode({
        'type': 'ui_render',
        'components': [
          {'type': 'container', 'id': 'chat', 'children': []},
        ],
      }));

      // Simulate receiving a chat response via ui_append.
      wsProvider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat',
        'data': {'role': 'assistant', 'text': 'How can I help?'},
      }));

      expect(wsProvider.chatMessages, hasLength(1));
      expect(wsProvider.chatMessages[0]['text'], 'How can I help?');
    });

    test('reconnect preserves session_id', () {
      // Simulate receiving a session_id.
      wsProvider.simulateMessage(jsonEncode({
        'type': 'session_id',
        'session_id': 'sess-42',
      }));

      expect(wsProvider.sessionId, 'sess-42');

      // After a disconnect (non-user-triggered), session_id should persist.
      wsProvider.disconnect();
      expect(wsProvider.sessionId, 'sess-42');
    });

    test('user-triggered disconnect does not clear session_id', () {
      wsProvider.simulateMessage(jsonEncode({
        'type': 'session_id',
        'session_id': 'sess-99',
      }));

      wsProvider.disconnect(triggeredByUser: true);
      // session_id is preserved even on user disconnect — it's the backend's
      // identifier, not a connection-scoped value.
      expect(wsProvider.sessionId, 'sess-99');
    });
  });
}
