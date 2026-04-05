// T010 — LoginPage widget tests
//
// Verifies rendering of the unified login page that shows both
// username/password form AND SSO button with glass-morphism styling.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:astral/components/auth/login_page.dart';
import 'package:astral/state/auth_provider.dart';

@GenerateNiceMocks([MockSpec<AuthProvider>()])
import 'login_page_test.mocks.dart';

/// Helper to pump the LoginPage with a mock AuthProvider injected via Provider.
Widget _buildTestWidget(MockAuthProvider mockAuth) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuth,
        child: const LoginPage(),
      ),
    ),
  );
}

void main() {
  late MockAuthProvider mockAuth;

  setUp(() {
    mockAuth = MockAuthProvider();
    // Default idle state
    when(mockAuth.isLoading).thenReturn(false);
    when(mockAuth.isAuthenticated).thenReturn(false);
    when(mockAuth.error).thenReturn(null);
    when(mockAuth.profile).thenReturn(AuthProfile.initial());
    when(mockAuth.token).thenReturn(null);
  });

  group('LoginPage rendering', () {
    testWidgets('renders username text field', (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      // Find by label text
      expect(find.text('Username'), findsOneWidget);
      // Also verify there is a TextField with the person icon
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('renders password text field', (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders SSO "Sign in with SSO" button', (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('Sign in with SSO'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders "AstralDeep" branding text', (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('AstralDeep'), findsOneWidget);
    });

    testWidgets('renders subtitle branding text', (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('AI-Powered Research Platform'), findsOneWidget);
    });

    testWidgets('renders "OR" divider between forms', (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('renders Sign In elevated button', (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('LoginPage loading state', () {
    testWidgets('shows CircularProgressIndicator when isLoading is true',
        (tester) async {
      when(mockAuth.isLoading).thenReturn(true);

      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // "Sign In" text should NOT be visible while loading
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('disables text fields when isLoading is true',
        (tester) async {
      when(mockAuth.isLoading).thenReturn(true);

      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      // Both TextFields should be disabled
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        expect(tf.enabled, isFalse,
            reason: 'TextField should be disabled while loading');
      }
    });

    testWidgets('disables Sign In button when isLoading is true',
        (tester) async {
      when(mockAuth.isLoading).thenReturn(true);

      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull,
          reason: 'Button should be disabled while loading');
    });

    testWidgets('disables SSO button when isLoading is true', (tester) async {
      when(mockAuth.isLoading).thenReturn(true);

      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      final button =
          tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull,
          reason: 'SSO button should be disabled while loading');
    });
  });

  group('LoginPage error display', () {
    testWidgets('displays error message when auth.error is set',
        (tester) async {
      when(mockAuth.error).thenReturn('Invalid credentials');

      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('does not display error container when auth.error is null',
        (tester) async {
      when(mockAuth.error).thenReturn(null);

      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });

  group('LoginPage form visibility', () {
    testWidgets(
        'both password form and SSO button are visible regardless of config',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      // Password form elements
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // SSO elements
      expect(find.text('Sign in with SSO'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
    });
  });
}
