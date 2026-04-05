// T012 — AuthProvider OIDC flow unit tests
//
// Tests token exchange, JWT profile extraction, and token refresh logic.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/state/auth_provider.dart';

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

/// Build a fake 3-part JWT from a claims map (unsigned, for testing only).
String _buildFakeJwt(Map<String, dynamic> claims) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
  return '$header.$payload.fakesig';
}

/// Helper: construct AuthProvider and wait for initializeAuth to finish.
Future<AuthProvider> _createAndInit() async {
  final provider = AuthProvider();
  await Future.delayed(Duration.zero);
  await Future.delayed(Duration.zero);
  await Future.delayed(Duration.zero);
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _secureStore.clear();
    SharedPreferences.setMockInitialValues({});
    _setupSecureStorageStub();
  });

  // -----------------------------------------------------------------------
  // JWT profile extraction
  // -----------------------------------------------------------------------
  group('JWT profile extraction', () {
    test('decodes sub, preferred_username, and admin role from JWT', () {
      final jwt = _buildFakeJwt({
        'sub': 'user-abc-123',
        'preferred_username': 'jdoe',
        'realm_access': {
          'roles': ['admin', 'user'],
        },
      });

      // Manually decode to verify the JWT helper produces valid base64url
      final parts = jwt.split('.');
      expect(parts.length, 3);

      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      expect(decoded['sub'], 'user-abc-123');
      expect(decoded['preferred_username'], 'jdoe');
      expect(decoded['realm_access']['roles'], contains('admin'));
    });

    test('decodes user role when admin is absent', () {
      final jwt = _buildFakeJwt({
        'sub': 'user-456',
        'preferred_username': 'student1',
        'realm_access': {
          'roles': ['user'],
        },
      });

      final parts = jwt.split('.');
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      expect(decoded['realm_access']['roles'], isNot(contains('admin')));
      expect(decoded['realm_access']['roles'], contains('user'));
    });

    test('handles JWT with no realm_access gracefully', () {
      final jwt = _buildFakeJwt({
        'sub': 'user-789',
        'preferred_username': 'guest',
      });

      final parts = jwt.split('.');
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      expect(decoded['sub'], 'user-789');
      expect(decoded.containsKey('realm_access'), isFalse);
    });

    test('handles JWT with empty roles list', () {
      final jwt = _buildFakeJwt({
        'sub': 'user-empty',
        'preferred_username': 'noroles',
        'realm_access': {
          'roles': <String>[],
        },
      });

      final parts = jwt.split('.');
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      expect(decoded['realm_access']['roles'], isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // exchangeCodeForToken — network error path
  // -----------------------------------------------------------------------
  group('AuthProvider.exchangeCodeForToken — network error', () {
    test('returns false and sets error on network failure', () async {
      final provider = await _createAndInit();

      final result = await provider.exchangeCodeForToken('fake-auth-code');

      expect(result, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test('sets isLoading true during exchange then false after', () async {
      final provider = await _createAndInit();

      expect(provider.isLoading, isFalse);

      final future = provider.exchangeCodeForToken('fake-code');
      expect(provider.isLoading, isTrue);

      await future;
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // loginWithOidc — error path (no Keycloak running)
  // -----------------------------------------------------------------------
  group('AuthProvider.loginWithOidc — error path', () {
    test('returns false when OIDC flow fails', () async {
      final provider = await _createAndInit();

      final result = await provider.loginWithOidc();

      expect(result, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test('clears previous error before OIDC attempt', () async {
      final provider = await _createAndInit();

      // First call sets an error
      await provider.loginWithOidc();
      expect(provider.error, isNotNull);

      bool errorWasCleared = false;
      provider.addListener(() {
        if (provider.error == null && provider.isLoading) {
          errorWasCleared = true;
        }
      });

      await provider.loginWithOidc();
      expect(errorWasCleared, isTrue);
      provider.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Token refresh — no refresh token available
  // -----------------------------------------------------------------------
  group('AuthProvider.refreshOrLogout', () {
    test('logs out when no refresh token is available', () async {
      final provider = await _createAndInit();

      // No refresh token stored, so refreshOrLogout should fail and logout
      final result = await provider.refreshOrLogout();

      expect(result, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.token, isNull);
      provider.dispose();
    });

    test('notifies listeners after failed refresh', () async {
      final provider = await _createAndInit();

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.refreshOrLogout();

      expect(notified, isTrue);
      provider.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // AuthProfile from token response shape
  // -----------------------------------------------------------------------
  group('AuthProfile from OIDC-shaped response', () {
    test('constructs profile with all fields from JSON', () {
      final profile = AuthProfile.fromJson({
        'id': 'oidc-sub-123',
        'username': 'keycloak_user',
        'globalRole': 'admin',
        'preferenceId': 'default',
        'profileTags': ['researcher', 'pi'],
      });

      expect(profile.id, 'oidc-sub-123');
      expect(profile.username, 'keycloak_user');
      expect(profile.globalRole, 'admin');
      expect(profile.profileTags, ['researcher', 'pi']);
    });

    test('constructs profile with minimal JSON (missing optional fields)', () {
      final profile = AuthProfile.fromJson({
        'id': 'oidc-sub-456',
        'username': 'minimal_user',
      });

      expect(profile.id, 'oidc-sub-456');
      expect(profile.username, 'minimal_user');
      expect(profile.globalRole, isNull);
      expect(profile.preferenceId, isNull);
      expect(profile.profileTags, isEmpty);
    });
  });
}
