import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthProfile {
  final String? id;
  final String? username;
  final String? globalRole;
  final String? preferenceId;
  final List<String> profileTags;

  const AuthProfile({
    this.id,
    this.username,
    this.globalRole,
    this.preferenceId = 'default',
    this.profileTags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'globalRole': globalRole,
        'preferenceId': preferenceId,
        'profileTags': profileTags,
      };

  factory AuthProfile.fromJson(Map<String, dynamic> json) => AuthProfile(
        id: json['id'],
        username: json['username'],
        globalRole: json['globalRole'],
        preferenceId: json['preferenceId'],
        profileTags: List<String>.from(json['profileTags'] ?? []),
      );

  factory AuthProfile.initial() => const AuthProfile();
}

/// Authentication provider supporting Keycloak OIDC (via BFF proxy) and
/// mock auth fallback. Stores JWT in secure storage and performs silent
/// refresh using the refresh token.
class AuthProvider extends ChangeNotifier {
  final _logger = Logger();
  final _secureStorage = const FlutterSecureStorage();

  AuthProfile _profile = AuthProfile.initial();
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  AuthProfile get profile => _profile;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    initializeAuth();
  }

  Future<void> initializeAuth() async {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Try to restore session from secure storage
      final storedToken = await _secureStorage.read(key: 'auth_token');
      final storedRefresh = await _secureStorage.read(key: 'refresh_token');
      final expiryStr = await _secureStorage.read(key: 'token_expiry');

      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString('auth_profile');

      if (storedToken != null && profileString != null) {
        _token = storedToken;
        _refreshToken = storedRefresh;
        _profile = AuthProfile.fromJson(jsonDecode(profileString));

        if (expiryStr != null) {
          _tokenExpiry = DateTime.tryParse(expiryStr);
        }

        // If token is expired, try silent refresh
        if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
          _logger.i('[AUTH] Token expired, attempting silent refresh');
          final refreshed = await _silentRefresh();
          if (!refreshed) {
            _logger.w('[AUTH] Silent refresh failed, clearing session');
            await _clearSession();
            _isLoading = false;
            notifyListeners();
            return;
          }
        }

        _isAuthenticated = true;
        _logger.i('[AUTH] Session restored for user: ${_profile.username}');
      }
    } catch (e, s) {
      _logger.e('Failed to initialize auth', error: e, stackTrace: s);
      await _clearSession();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mock auth login (when MOCK_AUTH=true). Posts username/password to /auth/login.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _profile = AuthProfile(
          id: data['user']?['id']?.toString() ?? '',
          username: data['user']?['username'] ?? username,
          globalRole: data['user']?['globalRole'] ?? 'user',
          preferenceId: data['user']?['preferenceId'] ?? 'default',
          profileTags: List<String>.from(data['user']?['profileTags'] ?? []),
        );
        _token = data['access_token'];
        _isAuthenticated = true;
        _tokenExpiry = DateTime.now().add(const Duration(hours: 2));

        await _saveSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _logger.e('[AUTH] Login error', error: e, stackTrace: s);
      _error = 'Login error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Exchange an OIDC authorization code for tokens via the backend BFF proxy.
  Future<bool> exchangeCodeForToken(String authorizationCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': authorizationCode,
          'redirect_uri': 'com.astralbody.app://callback',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return await _handleTokenResponse(data);
      } else {
        _error = 'Token exchange failed: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _logger.e('[AUTH] Token exchange error', error: e, stackTrace: s);
      _error = 'Token exchange error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Silent JWT refresh using stored refresh token.
  Future<bool> _silentRefresh() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return await _handleTokenResponse(data, silent: true);
      }
      return false;
    } catch (e) {
      _logger.w('[AUTH] Silent refresh error: $e');
      return false;
    }
  }

  Future<bool> _handleTokenResponse(Map<String, dynamic> data,
      {bool silent = false}) async {
    _token = data['access_token'];
    _refreshToken = data['refresh_token'];
    final expiresIn = data['expires_in'] as int? ?? 300;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

    // Decode JWT payload for profile info
    if (!silent) {
      _profile = _decodeJwtProfile(_token!);
    }

    _isAuthenticated = true;
    await _saveSession();

    if (!silent) {
      _isLoading = false;
      notifyListeners();
    }
    return true;
  }

  AuthProfile _decodeJwtProfile(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return _profile;
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return AuthProfile(
        id: payload['sub'] ?? '',
        username: payload['preferred_username'] ?? payload['sub'] ?? '',
        globalRole: (payload['realm_access']?['roles'] as List?)
                ?.firstWhere((r) => r == 'admin', orElse: () => 'user') ??
            'user',
      );
    } catch (_) {
      return _profile;
    }
  }

  Future<void> logout() async {
    _profile = AuthProfile.initial();
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _isAuthenticated = false;
    await _clearSession();
    notifyListeners();
  }

  Future<void> _saveSession() async {
    await _secureStorage.write(key: 'auth_token', value: _token);
    if (_refreshToken != null) {
      await _secureStorage.write(key: 'refresh_token', value: _refreshToken);
    }
    if (_tokenExpiry != null) {
      await _secureStorage.write(
          key: 'token_expiry', value: _tokenExpiry!.toIso8601String());
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_profile', jsonEncode(_profile.toJson()));
  }

  Future<void> _clearSession() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_profile');
    _isAuthenticated = false;
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }
}
