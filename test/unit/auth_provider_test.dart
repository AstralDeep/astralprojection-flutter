// T021 — AuthProvider unit tests
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/state/auth_provider.dart';

void main() {
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
  });

  group('AuthProvider', () {
    setUp(() {
      // Ensure clean SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state has isLoading true', () {
      // AuthProvider calls initializeAuth in constructor, which sets
      // isLoading = true at the start.
      final provider = AuthProvider();
      // Right after construction (before async completes), isLoading is true
      expect(provider.isLoading, isTrue);
      provider.dispose();
    });

    test('initial state has isAuthenticated false', () {
      final provider = AuthProvider();
      expect(provider.isAuthenticated, isFalse);
      provider.dispose();
    });

    test('initial state has null token', () {
      final provider = AuthProvider();
      expect(provider.token, isNull);
      provider.dispose();
    });

    test('initial profile is AuthProfile.initial()', () {
      final provider = AuthProvider();
      expect(provider.profile.id, isNull);
      expect(provider.profile.username, isNull);
      provider.dispose();
    });

    test('after initialization with no saved session, isAuthenticated is false',
        () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AuthProvider();

      // Wait for initializeAuth to complete
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test('logout clears authentication state', () async {
      final provider = AuthProvider();
      // Wait for init to finish
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await provider.logout();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.token, isNull);
      expect(provider.profile.id, isNull);
      expect(provider.profile.username, isNull);
      provider.dispose();
    });

    test('logout notifies listeners', () async {
      final provider = AuthProvider();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.logout();

      expect(notified, isTrue);
      provider.dispose();
    });

    test('error is null initially', () {
      final provider = AuthProvider();
      expect(provider.error, isNull);
      provider.dispose();
    });
  });
}
