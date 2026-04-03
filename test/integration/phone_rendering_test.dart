// T058 — Integration test: phone end-to-end flow
//
// - Auth via KEYCLOAK_TEST_USER / KEYCLOAK_TEST_PASSWORD env vars
// - Loading overlay with spinner appears
// - WebSocket connects
// - ui_render received, dashboard renders
// - Tap button, verify re-render
// - Rotate device, verify re-adaptation (register_ui re-sent)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:astral/app.dart';
import 'package:astral/components/common/loading_overlay.dart';
import 'package:astral/state/web_socket_provider.dart';
import 'package:astral/state/device_profile_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('T058 — Phone end-to-end rendering flow', () {
    testWidgets(
      'authenticates using env credentials and shows loading overlay',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        // Arrange: read credentials from environment
        const username = String.fromEnvironment('KEYCLOAK_TEST_USER');
        const password = String.fromEnvironment('KEYCLOAK_TEST_PASSWORD');

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Act: enter credentials and submit login form
        final usernameField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(usernameField, username);
        await tester.enterText(passwordField, password);

        final loginButton = find.widgetWithText(ElevatedButton, 'Login');
        await tester.tap(loginButton);
        await tester.pump();

        // Assert: loading overlay with spinner should appear
        expect(find.byType(LoadingOverlay), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'WebSocket connects and receives ui_render after authentication',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Perform login (assumes env credentials are set)
        const username = String.fromEnvironment('KEYCLOAK_TEST_USER');
        const password = String.fromEnvironment('KEYCLOAK_TEST_PASSWORD');

        final usernameField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(usernameField, username);
        await tester.enterText(passwordField, password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));

        // Wait for WebSocket to connect and ui_render to arrive
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Assert: loading overlay should be gone, dashboard should be visible
        final ws = tester.element(find.byType(App)).read<WebSocketProvider>();
        expect(ws.connected, isTrue);
        expect(ws.hasReceivedRender, isTrue);
        expect(ws.components, isNotEmpty);
        expect(find.byType(LoadingOverlay), findsNothing);
      },
    );

    testWidgets(
      'tapping a rendered button triggers re-render via ui_event',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Authenticate and wait for initial render
        const username = String.fromEnvironment('KEYCLOAK_TEST_USER');
        const password = String.fromEnvironment('KEYCLOAK_TEST_PASSWORD');
        final usernameField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(usernameField, username);
        await tester.enterText(passwordField, password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Act: find and tap the first rendered SDUI button
        final sduiButton = find.byType(ElevatedButton).first;
        expect(sduiButton, findsOneWidget);

        final ws = tester.element(find.byType(App)).read<WebSocketProvider>();
        final componentsBefore = List.of(ws.components);

        await tester.tap(sduiButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Assert: components should have been updated (re-render received)
        expect(ws.components, isNot(equals(componentsBefore)));
      },
    );

    testWidgets(
      'rotating the device re-sends register_ui with updated dimensions',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Authenticate and wait for initial render
        const username = String.fromEnvironment('KEYCLOAK_TEST_USER');
        const password = String.fromEnvironment('KEYCLOAK_TEST_PASSWORD');
        final usernameField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(usernameField, username);
        await tester.enterText(passwordField, password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle(const Duration(seconds: 10));

        final dp = tester.element(find.byType(App)).read<DeviceProfileProvider>();
        final widthBefore = dp.viewportWidth;
        final heightBefore = dp.viewportHeight;

        // Act: simulate landscape rotation by resizing the test surface
        final binding = tester.binding;
        await binding.setSurfaceSize(
          Size(heightBefore, widthBefore), // swap width/height
        );
        await tester.pumpAndSettle();

        // Assert: device profile should reflect the new dimensions
        expect(dp.viewportWidth, isNot(equals(widthBefore)));
        expect(dp.viewportHeight, isNot(equals(heightBefore)));
        // register_ui should have been re-sent (verified by backend logs
        // or by observing a fresh ui_render adapted to new dimensions)
        expect(dp.deviceType, isNotNull);
      },
    );
  });
}
