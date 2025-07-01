import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // --- NEW: Create AuthProfile instance from a Map ---
  factory AuthProfile.fromJson(Map<String, dynamic> json) => AuthProfile(
    id: json['id'],
    username: json['username'],
    globalRole: json['globalRole'],
    preferenceId: json['preferenceId'],
    profileTags: List<String>.from(json['profileTags'] ?? []),
  );

  factory AuthProfile.initial() => const AuthProfile();
}

class AuthProvider extends ChangeNotifier {
  final _logger = Logger();

  AuthProfile _profile = AuthProfile.initial();
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = true; // Start in a loading state
  String? _error;

  AuthProfile get profile => _profile;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    initializeAuth();
  }

  // --- MODIFIED: Added a robust try/catch/finally block ---
  Future<void> initializeAuth() async {
    // Ensure we start in a loading state
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionExpiry = prefs.getInt('session_expiry');

      _logger.i('[AUTH INIT] Checking for session...');
      _logger.d('[AUTH INIT] Found expiry timestamp: $sessionExpiry');

      if (sessionExpiry != null && DateTime.now().millisecondsSinceEpoch < sessionExpiry) {
        _logger.i('[AUTH INIT] Session is not expired. Restoring...');
        _token = prefs.getString('auth_token');
        final profileString = prefs.getString('auth_profile');

        _logger.d('[AUTH INIT] Retrieved token: $_token');
        _logger.d('[AUTH INIT] Retrieved profile string: $profileString');

        if (_token != null && profileString != null) {
          _profile = AuthProfile.fromJson(jsonDecode(profileString));
          _isAuthenticated = true;
          _logger.i('[AUTH INIT] Session restored successfully for user: ${_profile.username}');
        } else {
          _logger.w('[AUTH INIT] Session expired or data was missing. Clearing session.');
          await _clearSession(prefs);
        }
      } else {
        _logger.i('[AUTH INIT] No valid session found.');
        await _clearSession(prefs);
      }
    } catch (e, s) {
      // If any error occurs (e.g., corrupted data), log it and clear the session
      _logger.e('Failed to initialize auth', error: e, stackTrace: s);
      final prefs = await SharedPreferences.getInstance();
      await _clearSession(prefs);
    } finally {
      // This block will always run, ensuring the loading spinner is hidden
      _isLoading = false;
      notifyListeners();
    }
  }

  // Your login and logout methods remain the same...
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      _logger.i('[AuthProvider] Login response status: ${response.statusCode}');

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
        
        await _saveSession();
        _logger.i('Login successful, session saved for user: ${profile.username}');

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
      _logger.e('[AuthProvider] Login error', error: e, stackTrace: s);
      _error = 'Login error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _profile = AuthProfile.initial();
    _token = null;
    _isAuthenticated = false;
    
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    _logger.i('User logged out and session cleared');

    notifyListeners();
  }
  
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch;
    
    await prefs.setInt('session_expiry', expiryTime);
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_profile', jsonEncode(_profile.toJson()));
  }
  
  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove('session_expiry');
    await prefs.remove('auth_token');
    await prefs.remove('auth_profile');
  }
}