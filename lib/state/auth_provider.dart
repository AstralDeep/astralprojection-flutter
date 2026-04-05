import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
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
  final _appAuth = const FlutterAppAuth();

  AuthProfile _profile = AuthProfile.initial();
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  AuthProfile get profile => _profile;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;
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
        _token = data['access_token'];

        // Try to decode JWT for profile
        if (_token != null && _token!.contains('.')) {
          _profile = _decodeJwtProfile(_token!);
        } else {
          _profile = AuthProfile(
            id: data['user']?['id']?.toString() ?? '',
            username: data['user']?['username'] ?? username,
            globalRole: _extractGlobalRole(data['user']?['roles']),
            preferenceId: data['user']?['preferenceId'] ?? 'default',
            profileTags: List<String>.from(data['user']?['profileTags'] ?? []),
          );
        }

        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 2));
        _isAuthenticated = true;

        await _saveSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _error = 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        _error = 'Login failed: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _logger.e('[AUTH] Login error', error: e, stackTrace: s);
      _error = 'Cannot reach server. Please check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Keycloak OIDC login via flutter_appauth authorization code + PKCE flow.
  ///
  /// Opens the system browser for Keycloak authentication, then exchanges
  /// the authorization code via the backend BFF proxy at /auth/token
  /// (so the client_secret stays server-side).
  Future<bool> loginWithOidc() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final serviceConfig = AuthorizationServiceConfiguration(
        authorizationEndpoint:
            '${AppConfig.keycloakAuthority}/protocol/openid-connect/auth',
        tokenEndpoint: AppConfig.bffTokenEndpoint,
      );

      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.keycloakClientId,
          AppConfig.oidcRedirectUri,
          serviceConfiguration: serviceConfig,
          scopes: AppConfig.oidcScopes,
          allowInsecureConnections: AppConfig.apiBaseUrl.startsWith('http://'),
        ),
      );

      _token = result.accessToken;
      _refreshToken = result.refreshToken;
      if (result.accessTokenExpirationDateTime != null) {
        _tokenExpiry = result.accessTokenExpirationDateTime;
      } else {
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 5));
      }

      // Extract profile from JWT claims
      if (_token != null) {
        _profile = _decodeJwtProfile(_token!);
      }

      _isAuthenticated = true;
      await _saveSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e('[AUTH] OIDC login error', error: e, stackTrace: s);
      if (e.toString().contains('CANCELED') ||
          e.toString().contains('cancelled')) {
        _error = 'SSO login was cancelled';
      } else {
        _error = 'Keycloak is unreachable. Please try again or use username/password login.';
      }
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
          'redirect_uri': AppConfig.oidcRedirectUri,
          'client_id': AppConfig.keycloakClientId,
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
          'client_id': AppConfig.keycloakClientId,
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

  /// Attempt silent refresh and redirect to login on failure.
  Future<bool> refreshOrLogout() async {
    final success = await _silentRefresh();
    if (!success) {
      _logger.w('[AUTH] Refresh failed, redirecting to login');
      await logout();
    }
    return success;
  }

  Future<bool> _handleTokenResponse(Map<String, dynamic> data,
      {bool silent = false}) async {
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) return false;
    _token = accessToken;
    _refreshToken = data['refresh_token'] as String?;
    final expiresIn = data['expires_in'] as int? ?? 300;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

    // Decode JWT payload for profile info
    if (!silent) {
      _profile = _decodeJwtProfile(accessToken);
    }

    _isAuthenticated = true;
    await _saveSession();

    if (!silent) {
      _isLoading = false;
      notifyListeners();
    }
    return true;
  }

  /// Decode JWT payload and extract user profile (sub, preferred_username,
  /// realm_access.roles).
  AuthProfile _decodeJwtProfile(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return _profile;
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return AuthProfile(
        id: payload['sub'] ?? '',
        username: payload['preferred_username'] ?? payload['sub'] ?? '',
        globalRole: _extractGlobalRole(
            payload['realm_access']?['roles'] as List?),
      );
    } catch (_) {
      return _profile;
    }
  }

  String _extractGlobalRole(List? roles) {
    if (roles == null) return 'user';
    if (roles.contains('admin')) return 'admin';
    if (roles.contains('user')) return 'user';
    return 'user';
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
