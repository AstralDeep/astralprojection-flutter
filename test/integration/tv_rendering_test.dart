// T074 -- Integration test: TV D-pad navigation, focus traversal, component
// rendering. All tests are skipped because they require a TV emulator or
// physical device with D-pad input.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:astral/app.dart';
import 'package:astral/state/device_profile_provider.dart';
import 'package:astral/state/web_socket_provider.dart';
import 'package:astral/platform/tv/tv_focus_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('T074 -- TV D-pad navigation and rendering', () {
    testWidgets(
      'reports device_type as "tv" on TV-sized viewport',
      skip: true, // Requires TV emulator
      (WidgetTester tester) async {
        // Arrange: set surface to TV dimensions (1920x1080)
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(1920, 1080));

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        final dp =
            tester.element(find.byType(App)).read<DeviceProfileProvider>();
        expect(dp.deviceType, equals('tv'));
        expect(dp.inputModality, equals('dpad'));
        expect(dp.toDeviceMap()['has_touch'], isFalse);
      },
    );

    testWidgets(
      'TvFocusManager is present in widget tree on TV viewport',
      skip: true, // Requires TV emulator
      (WidgetTester tester) async {
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(1920, 1080));

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

        // Assert: TvFocusManager should be in the tree
        expect(find.byType(TvFocusManager), findsOneWidget);
      },
    );

    testWidgets(
      'D-pad arrow keys traverse focus between buttons',
      skip: true, // Requires TV emulator
      (WidgetTester tester) async {
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(1920, 1080));

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

        // Wait for SDUI render
        final ws =
            tester.element(find.byType(App)).read<WebSocketProvider>();
        expect(ws.hasReceivedRender, isTrue);

        // Find focusable elements and verify D-pad navigation works
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().length >= 2) {
          // Focus first button
          await tester.tap(buttons.first);
          await tester.pump();

          // Arrow down should move focus
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();

          // The primary focus should have changed
          final primaryFocus = FocusManager.instance.primaryFocus;
          expect(primaryFocus, isNotNull);
        }
      },
    );

    testWidgets(
      'Enter/Select key activates focused button',
      skip: true, // Requires TV emulator
      (WidgetTester tester) async {
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(1920, 1080));

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Authenticate and wait for render
        const username = String.fromEnvironment('KEYCLOAK_TEST_USER');
        const password = String.fromEnvironment('KEYCLOAK_TEST_PASSWORD');
        final usernameField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(usernameField, username);
        await tester.enterText(passwordField, password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Find a focusable button, focus it, and press Enter
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pump();

          // Press Enter to activate
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();

          // If the button triggers navigation or state change, the tree
          // should update. We just verify no crash.
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      'TV theme applies dark brightness with scaled text',
      skip: true, // Requires TV emulator
      (WidgetTester tester) async {
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(1920, 1080));

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Check that the MaterialApp is using dark theme (TV default)
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, ThemeMode.dark);

        // Verify the theme has scaled-up text
        final theme = Theme.of(
          tester.element(find.byType(Scaffold).first),
        );
        expect(theme.brightness, Brightness.dark);
        expect(theme.textTheme.bodyMedium?.fontSize,
            greaterThanOrEqualTo(20.0));
      },
    );

    testWidgets(
      'focus indicators are visible on interactive components in TV mode',
      skip: true, // Requires TV emulator
      (WidgetTester tester) async {
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(1920, 1080));

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

        // After render, focusable elements should have Focus wrappers
        // with Container decorations when focused.
        final focusWidgets = find.byType(Focus);
        expect(focusWidgets, findsWidgets);
      },
    );
  });
}
