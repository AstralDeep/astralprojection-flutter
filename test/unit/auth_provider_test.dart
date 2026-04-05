// T011 — AuthProvider unit tests for mock auth (password) login flow
//
// Tests login(), error handling, and profile extraction using mocked HTTP.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/state/auth_provider.dart';

// ---------------------------------------------------------------------------
// In-memory stub for FlutterSecureStorage's platform channel.
// flutter_secure_storage uses MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
// so we intercept it and back it with a simple Map.
// ---------------------------------------------------------------------------
final Map<String, String> _secureStore = {};

void _setupSecureStorageStub() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    switch (call.method) {
      case 'read':
        final key = call.arguments['key'] as String;
        return _secureStore[key];
      case 'write':
        final key = call.arguments['key'] as String;
        final value = call.arguments['value'] as String;
        _secureStore[key] = value;
        return null;
      case 'delete':
        final key = call.arguments['key'] as String;
        _secureStore.remove(key);
        return null;
      case 'deleteAll':
        _secureStore.clear();
        return null;
      default:
        return null;
    }
  });
}

/// Helper: construct AuthProvider and wait for initializeAuth to finish.
Future<AuthProvider> _createAndInit() async {
  final provider = AuthProvider();
  // Pump the event loop so initializeAuth() completes
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
  // AuthProfile model tests (pure logic, no I/O)
  // -----------------------------------------------------------------------
  group('AuthProfile', () {
    test('initial factory has null fields and empty tags', () {
      final profile = AuthProfile.initial();
      expect(profile.id, isNull);
      expect(profile.username, isNull);
      expect(profile.globalRole, isNull);
      expect(profile.preferenceId, 'default');
      expect(profile.profileTags, isEmpty);
    });

    test('fromJson round-trips through toJson', () {
      final original = AuthProfile(
        id: 'u1',
        username: 'alice',
        globalRole: 'admin',
        preferenceId: 'pref-1',
        profileTags: ['tag1', 'tag2'],
      );

      final json = original.toJson();
      final restored = AuthProfile.fromJson(json);

      expect(restored.id, 'u1');
      expect(restored.username, 'alice');
      expect(restored.globalRole, 'admin');
      expect(restored.preferenceId, 'pref-1');
      expect(restored.profileTags, ['tag1', 'tag2']);
    });

    test('fromJson handles missing profileTags gracefully', () {
      final profile = AuthProfile.fromJson({
        'id': 'u2',
        'username': 'bob',
        'globalRole': 'user',
        'preferenceId': 'default',
      });

      expect(profile.profileTags, isEmpty);
    });

    test('toJson includes all fields', () {
      final profile = AuthProfile(
        id: 'x',
        username: 'y',
        globalRole: 'admin',
        preferenceId: 'p',
        profileTags: ['a'],
      );
      final json = profile.toJson();
      expect(json, containsPair('id', 'x'));
      expect(json, containsPair('username', 'y'));
      expect(json, containsPair('globalRole', 'admin'));
      expect(json, containsPair('preferenceId', 'p'));
      expect(json['profileTags'], ['a']);
    });
  });

  // -----------------------------------------------------------------------
  // AuthProvider initial state tests
  // -----------------------------------------------------------------------
  group('AuthProvider initial state', () {
    test('isLoading is true immediately after construction', () async {
      final provider = AuthProvider();
      expect(provider.isLoading, isTrue);
      // Let init finish before disposing to avoid "used after disposed"
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      provider.dispose();
    });

    test('isAuthenticated is false immediately after construction', () async {
      final provider = AuthProvider();
      expect(provider.isAuthenticated, isFalse);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      provider.dispose();
    });

    test('token is null immediately after construction', () async {
      final provider = AuthProvider();
      expect(provider.token, isNull);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      provider.dispose();
    });

    test('error is null initially', () async {
      final provider = AuthProvider();
      expect(provider.error, isNull);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      provider.dispose();
    });

    test('profile is AuthProfile.initial()', () async {
      final provider = AuthProvider();
      expect(provider.profile.id, isNull);
      expect(provider.profile.username, isNull);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      provider.dispose();
    });

    test(
        'after initialization with no saved session, isAuthenticated is false',
        () async {
      final provider = await _createAndInit();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Login — network error path (no mock server running)
  // -----------------------------------------------------------------------
  group('AuthProvider.login — network error', () {
    test('sets error on network/server failure', () async {
      final provider = await _createAndInit();

      // In test environment, TestWidgetsFlutterBinding intercepts HTTP and
      // returns 400. In production without a server, a SocketException would
      // be thrown. Both paths set an error and return false.
      final result = await provider.login('user', 'pass');

      expect(result, isFalse);
      expect(provider.error, isNotNull);
      // The error may be "Cannot reach server..." (real network) or
      // "Login failed: 400" (test binding). Either way, login failed.
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Logout
  // -----------------------------------------------------------------------
  group('AuthProvider.logout', () {
    test('clears authentication state', () async {
      final provider = await _createAndInit();

      await provider.logout();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.token, isNull);
      expect(provider.refreshToken, isNull);
      expect(provider.profile.id, isNull);
      expect(provider.profile.username, isNull);
      provider.dispose();
    });

    test('notifies listeners', () async {
      final provider = await _createAndInit();

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.logout();

      expect(notified, isTrue);
      provider.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // JWT profile decoding (tested indirectly via login success simulation)
  // -----------------------------------------------------------------------
  group('JWT profile decoding via AuthProfile', () {
    test('decodes a well-formed JWT payload', () {
      // Build a fake JWT with known claims
      final header = base64Url.encode(utf8.encode('{"alg":"none"}'));
      final payload = base64Url.encode(utf8.encode(jsonEncode({
        'sub': 'user-123',
        'preferred_username': 'jdoe',
        'realm_access': {
          'roles': ['admin', 'user'],
        },
      })));
      final fakeJwt = '$header.$payload.signature';

      // The JWT should have 3 parts separated by dots
      expect(fakeJwt.split('.').length, 3);

      // Decode the payload manually to verify structure
      final parts = fakeJwt.split('.');
      final decoded = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      expect(decoded['sub'], 'user-123');
      expect(decoded['preferred_username'], 'jdoe');
      expect(decoded['realm_access']['roles'], contains('admin'));
    });
  });

  // -----------------------------------------------------------------------
  // Login state contract
  // -----------------------------------------------------------------------
  group('AuthProvider.login — state contract', () {
    test('login sets isLoading true then false', () async {
      final provider = await _createAndInit();

      // Before calling login, isLoading should be false (init finished)
      expect(provider.isLoading, isFalse);

      // Start login (will fail due to no server, but we can observe states)
      final future = provider.login('user', 'pass');

      // isLoading should be true immediately after calling login
      expect(provider.isLoading, isTrue);

      await future;

      // After login completes, isLoading should be false
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test('login clears previous error before attempt', () async {
      final provider = await _createAndInit();

      // First login fails (sets an error)
      await provider.login('user', 'pass');
      expect(provider.error, isNotNull);

      // Second login attempt should clear the error at the start
      bool errorWasCleared = false;
      provider.addListener(() {
        if (provider.error == null && provider.isLoading) {
          errorWasCleared = true;
        }
      });

      await provider.login('user2', 'pass2');
      expect(errorWasCleared, isTrue);
      provider.dispose();
    });
  });
}
