// T059 — Integration test: tablet layout adaptation
//
// - Same auth flow as phone tests
// - Verify device_type reported as "tablet"
// - Verify grid columns match tablet profile

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:astral/app.dart';
import 'package:astral/state/device_profile_provider.dart';
import 'package:astral/state/web_socket_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('T059 — Tablet layout adaptation', () {
    testWidgets(
      'reports device_type as "tablet" on tablet-sized viewport',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        // Arrange: set surface to tablet dimensions (768x1024)
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(768, 1024));

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

        // Assert: device profile reports tablet
        final dp = tester.element(find.byType(App)).read<DeviceProfileProvider>();
        expect(dp.deviceType, equals('tablet'));
        expect(dp.toDeviceMap()['device_type'], equals('tablet'));
        expect(dp.toDeviceMap()['has_touch'], isTrue);
      },
    );

    testWidgets(
      'register_ui device map contains tablet viewport dimensions',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(768, 1024));

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        final dp = tester.element(find.byType(App)).read<DeviceProfileProvider>();
        final deviceMap = dp.toDeviceMap();

        // Assert: viewport dimensions reflect tablet surface
        expect(deviceMap['viewport_width'], greaterThanOrEqualTo(481));
        expect(deviceMap['viewport_width'], lessThanOrEqualTo(1024));
        expect(deviceMap['device_type'], equals('tablet'));
      },
    );

    testWidgets(
      'grid columns adapt to tablet profile after ui_render',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        // Arrange: tablet viewport
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(768, 1024));

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

        // Assert: the rendered component tree should be present
        final ws = tester.element(find.byType(App)).read<WebSocketProvider>();
        expect(ws.hasReceivedRender, isTrue);

        // Verify grid columns in the rendered tree match tablet expectations.
        // The backend should send a grid with more columns for tablet vs. phone.
        // Look for a GridView in the widget tree and check its column count.
        final gridFinder = find.byType(GridView);
        if (gridFinder.evaluate().isNotEmpty) {
          final gridView = tester.widget<GridView>(gridFinder.first);
          final delegate = gridView.gridDelegate;
          if (delegate is SliverGridDelegateWithFixedCrossAxisCount) {
            // Tablet grids should have more columns than phone (typically 2-3+)
            expect(delegate.crossAxisCount, greaterThanOrEqualTo(2));
          }
        }
      },
    );

    testWidgets(
      'switching from tablet to phone viewport triggers device_type change',
      skip: true, // Requires device emulator
      (WidgetTester tester) async {
        // Start with tablet dimensions
        final binding = tester.binding;
        await binding.setSurfaceSize(const Size(768, 1024));

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        final dp = tester.element(find.byType(App)).read<DeviceProfileProvider>();
        expect(dp.deviceType, equals('tablet'));

        // Resize to phone dimensions
        await binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpAndSettle();

        // Assert: device type should now be mobile
        expect(dp.deviceType, equals('mobile'));
      },
    );
  });
}
