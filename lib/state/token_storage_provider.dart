import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal token storage provider — no OAuth logic, no Keycloak awareness.
/// Stores tokens pushed by the backend via ui_action(store_token).
class TokenStorageProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'auth_refresh_token';

  final _storage = const FlutterSecureStorage();

  String? _token;
  String? _refreshToken;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Store tokens received from the backend.
  Future<void> store(String token, String refreshToken, int expiresIn) async {
    _token = token;
    _refreshToken = refreshToken;
    notifyListeners();
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _refreshKey, value: refreshToken);
    } catch (_) {}
  }

  /// Clear stored tokens (on logout).
  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    notifyListeners();
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
  }

  /// Load cached tokens from secure storage on startup.
  Future<void> loadCached() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      _refreshToken = await _storage.read(key: _refreshKey);
      notifyListeners();
    } catch (_) {}
  }
}
