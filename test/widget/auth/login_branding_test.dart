// T037 — Login branding widget tests
//
// Verifies that "AstralDeep" branding and "AI-Powered Research Platform"
// tagline render correctly on the login page.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:astral/components/auth/login_page.dart';
import 'package:astral/state/auth_provider.dart';

// Reuse the generated mock from login_page_test.
import 'login_page_test.mocks.dart';

/// Helper to pump the LoginPage with a mock AuthProvider.
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
    when(mockAuth.isLoading).thenReturn(false);
    when(mockAuth.isAuthenticated).thenReturn(false);
    when(mockAuth.error).thenReturn(null);
    when(mockAuth.profile).thenReturn(AuthProfile.initial());
    when(mockAuth.token).thenReturn(null);
  });

  group('Login branding', () {
    testWidgets('renders "AstralDeep" branding text', (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('AstralDeep'), findsOneWidget);
    });

    testWidgets('renders "AI-Powered Research Platform" tagline',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      expect(find.text('AI-Powered Research Platform'), findsOneWidget);
    });

    testWidgets('both branding and tagline are visible on login page',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(mockAuth));
      await tester.pump();

      final brandingFinder = find.text('AstralDeep');
      final taglineFinder = find.text('AI-Powered Research Platform');

      expect(brandingFinder, findsOneWidget);
      expect(taglineFinder, findsOneWidget);

      // Verify both are descendants of the LoginPage
      expect(
        find.descendant(
          of: find.byType(LoginPage),
          matching: brandingFinder,
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LoginPage),
          matching: taglineFinder,
        ),
        findsOneWidget,
      );
    });
  });
}
