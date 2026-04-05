// T013 — Integration test skeleton for full login -> dashboard journey
//
// This test requires a running backend (or mock server). It is intended as a
// skeleton to be fleshed out once the CI environment provides a test backend.
//
// Run with:
//   flutter test integration_test --dart-define=BACKEND_HOST=localhost \
//       --dart-define=BACKEND_PORT=8001 --dart-define=MOCK_AUTH=true

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/components/auth/login_page.dart';
import 'package:astral/state/auth_provider.dart';

import '../helpers/env_helper.dart';

// ---------------------------------------------------------------------------
// In-memory stub for FlutterSecureStorage platform channel.
// ---------------------------------------------------------------------------
final Map<String, String> _secureStore = {};

void _setupSecureStorageStub() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    switch (call.method) {
      case 'read':
        return _secureStore[call.arguments['key'] as String];
      case 'write':
        _secureStore[call.arguments['key'] as String] =
            call.arguments['value'] as String;
        return null;
      case 'delete':
        _secureStore.remove(call.arguments['key'] as String);
        return null;
      case 'deleteAll':
        _secureStore.clear();
        return null;
      default:
        return null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _secureStore.clear();
    SharedPreferences.setMockInitialValues({});
    _setupSecureStorageStub();
  });

  // -----------------------------------------------------------------------
  // Skeleton: login -> dashboard navigation
  // -----------------------------------------------------------------------
  group('Auth integration — login to dashboard journey', () {
    testWidgets(
      'login with mock credentials navigates to dashboard',
      (tester) async {
        // Retrieve test credentials from env helper
        final username = EnvHelper.testUser;
        final password = EnvHelper.testPassword;

        var loginSucceeded = false;

        // Build a minimal app with LoginPage and an onLoginSuccess callback
        final authProvider = AuthProvider();

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: Scaffold(
                body: LoginPage(
                  onLoginSuccess: () {
                    loginSucceeded = true;
                  },
                ),
              ),
            ),
          ),
        );

        // Use loginSucceeded in assertion placeholder so the compiler
        // does not flag it as unused.
        expect(loginSucceeded, isFalse);

        // Wait for AuthProvider initialization to complete
        await tester.pumpAndSettle();

        // Verify the login page rendered
        expect(find.text('AstralDeep'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Sign in with SSO'), findsOneWidget);

        // Enter credentials into the form
        await tester.enterText(
          find.widgetWithText(TextField, 'Username'),
          username,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Password'),
          password,
        );
        await tester.pump();

        // Tap the Sign In button
        await tester.tap(find.text('Sign In'));
        await tester.pump();

        // NOTE: Without a running backend this will fail with a network error.
        // In a real CI environment with MOCK_AUTH=true and a running backend,
        // the following assertions would pass:
        //
        //   await tester.pumpAndSettle(const Duration(seconds: 5));
        //   expect(loginSucceeded, isTrue);
        //   expect(authProvider.isAuthenticated, isTrue);
        //   expect(authProvider.profile.username, isNotNull);

        // For now, verify the login attempt was initiated (isLoading becomes
        // true briefly, then settles with an error since no backend is up)
        await tester.pumpAndSettle();

        // After the attempt, the provider should no longer be loading
        expect(authProvider.isLoading, isFalse);

        authProvider.dispose();
      },
      // Skip in automated CI by default — requires running backend
      skip: true, // Requires running backend
    );

    testWidgets(
      'SSO button is present and tappable',
      (tester) async {
        final authProvider = AuthProvider();

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const Scaffold(
                body: LoginPage(),
              ),
            ),
          ),
        );

        // Wait for AuthProvider.initializeAuth to complete
        await tester.pumpAndSettle();

        // Verify SSO button renders
        final ssoButton = find.text('Sign in with SSO');
        expect(ssoButton, findsOneWidget);

        // Verify it is an OutlinedButton
        expect(find.byType(OutlinedButton), findsOneWidget);

        // After init settles, isLoading is false so button should be enabled
        final button =
            tester.widget<OutlinedButton>(find.byType(OutlinedButton));
        expect(button.onPressed, isNotNull,
            reason: 'SSO button should be enabled when not loading');

        authProvider.dispose();
      },
    );

    testWidgets(
      'error message appears after failed login attempt',
      (tester) async {
        final authProvider = AuthProvider();

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const Scaffold(
                body: LoginPage(),
              ),
            ),
          ),
        );

        // Wait for init to complete so fields are enabled
        await tester.pumpAndSettle();

        // Verify Sign In button is visible (init done, not loading)
        expect(find.text('Sign In'), findsOneWidget);

        // Enter credentials and tap Sign In (will fail — no real backend)
        await tester.enterText(
          find.widgetWithText(TextField, 'Username'),
          'testuser',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Password'),
          'wrongpassword',
        );
        await tester.tap(find.text('Sign In'));

        // Wait for the network call to complete (returns 400 in test binding)
        await tester.pumpAndSettle();

        // An error message should now be displayed
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(authProvider.error, isNotNull);

        authProvider.dispose();
      },
    );
  });
}
