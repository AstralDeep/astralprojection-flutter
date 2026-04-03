// T060 — Integration test: app restart shows cached SDUI tree
//
// - Connect and receive ui_render
// - Verify tree is persisted to SharedPreferences
// - Simulate app restart (recreate providers)
// - Verify cached tree is loaded and displayed
// - Verify fresh ui_render replaces cached tree

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/app.dart';
import 'package:astral/state/web_socket_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('T060 — Cached SDUI tree persistence and restoration', () {
    testWidgets(
      'ui_render tree is persisted to SharedPreferences',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Authenticate
        const username = String.fromEnvironment('KEYCLOAK_TEST_USER');
        const password = String.fromEnvironment('KEYCLOAK_TEST_PASSWORD');
        final usernameField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(usernameField, username);
        await tester.enterText(passwordField, password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Assert: WebSocket received a render
        final ws = tester.element(find.byType(App)).read<WebSocketProvider>();
        expect(ws.hasReceivedRender, isTrue);
        expect(ws.components, isNotEmpty);

        // Assert: tree was persisted to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('sdui_cached_tree');
        expect(cached, isNotNull);

        final decoded = jsonDecode(cached!);
        expect(decoded, isA<List>());
        expect((decoded as List).length, equals(ws.components.length));
      },
    );

    testWidgets(
      'app restart loads cached tree before WebSocket connects',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        // Arrange: pre-populate SharedPreferences with a cached SDUI tree
        final fakeCachedTree = [
          {
            'type': 'text',
            'id': 'cached-text-1',
            'props': {'content': 'Cached dashboard heading'},
          },
          {
            'type': 'card',
            'id': 'cached-card-1',
            'props': {'title': 'Cached Card'},
            'children': [],
          },
        ];
        SharedPreferences.setMockInitialValues({
          'sdui_cached_tree': jsonEncode(fakeCachedTree),
          'auth_profile': jsonEncode({
            'id': 'test-user',
            'username': 'testuser',
            'globalRole': 'user',
            'preferenceId': 'default',
            'profileTags': <String>[],
          }),
        });

        // Act: start the app (simulates restart)
        await tester.pumpWidget(const App());
        await tester.pump(); // Allow loadCachedTree to complete

        // Assert: the cached components should be loaded into the provider
        final ws = tester.element(find.byType(App)).read<WebSocketProvider>();
        // Allow the async loadCachedTree to complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(ws.components, isNotEmpty);
        expect(ws.components.length, equals(2));
        expect(ws.components[0]['id'], equals('cached-text-1'));
        expect(ws.components[1]['id'], equals('cached-card-1'));

        // hasReceivedRender should still be false (cached, not live)
        expect(ws.hasReceivedRender, isFalse);
      },
    );

    testWidgets(
      'fresh ui_render replaces the cached tree',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        // Arrange: start with a cached tree
        final staleCachedTree = [
          {
            'type': 'text',
            'id': 'stale-text-1',
            'props': {'content': 'Stale cached content'},
          },
        ];
        SharedPreferences.setMockInitialValues({
          'sdui_cached_tree': jsonEncode(staleCachedTree),
        });

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Authenticate to trigger WebSocket connection
        const username = String.fromEnvironment('KEYCLOAK_TEST_USER');
        const password = String.fromEnvironment('KEYCLOAK_TEST_PASSWORD');
        final usernameField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(usernameField, username);
        await tester.enterText(passwordField, password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));

        // Wait for live ui_render to arrive
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Assert: live render replaces the stale cache
        final ws = tester.element(find.byType(App)).read<WebSocketProvider>();
        expect(ws.hasReceivedRender, isTrue);
        expect(ws.components, isNotEmpty);

        // The stale component should no longer be present
        final hasStaleContent = ws.components.any(
          (c) => c['id'] == 'stale-text-1',
        );
        expect(hasStaleContent, isFalse);

        // SharedPreferences should now contain the fresh tree
        final prefs = await SharedPreferences.getInstance();
        final updatedCache = prefs.getString('sdui_cached_tree');
        expect(updatedCache, isNotNull);

        final updatedDecoded = jsonDecode(updatedCache!);
        expect(updatedDecoded, isA<List>());
        // Fresh tree should not contain the stale entry
        final freshHasStale = (updatedDecoded as List).any(
          (c) => c['id'] == 'stale-text-1',
        );
        expect(freshHasStale, isFalse);
      },
    );

    testWidgets(
      'cached tree is displayed in the UI widget tree on restart',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        // Arrange: pre-populate cache with a text component
        final cachedTree = [
          {
            'type': 'text',
            'id': 'cached-heading',
            'props': {'content': 'Welcome back (cached)'},
          },
        ];
        SharedPreferences.setMockInitialValues({
          'sdui_cached_tree': jsonEncode(cachedTree),
          'auth_profile': jsonEncode({
            'id': 'test-user',
            'username': 'testuser',
            'globalRole': 'user',
            'preferenceId': 'default',
            'profileTags': <String>[],
          }),
        });

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Assert: the cached text content should appear in the rendered widget tree
        // (exact finder depends on how DynamicRenderer renders "text" components)
        expect(find.text('Welcome back (cached)'), findsOneWidget);
      },
    );
  });
}
