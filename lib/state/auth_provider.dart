import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  factory AuthProfile.initial() => const AuthProfile();
}

class AuthProvider extends ChangeNotifier {
  AuthProfile _profile = AuthProfile.initial();
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  AuthProfile get profile => _profile;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initializeAuth() {
    // TODO: Load from persistent storage if needed
    _isAuthenticated = _token != null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Real API call to backend for authentication
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      print('[AuthProvider] Login response status: ${response.statusCode}');
      print('[AuthProvider] Login response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[AuthProvider] Parsed login data: ${data.toString()}');
        print('[AuthProvider] Received access_token: ${data['access_token']}');
        _profile = AuthProfile(
          id: data['user']?['id']?.toString() ?? '',
          username: data['user']?['username'] ?? username,
          globalRole: data['user']?['globalRole'] ?? 'user',
          preferenceId: data['user']?['preferenceId'] ?? 'default',
          profileTags: List<String>.from(data['user']?['profileTags'] ?? []),
        );
        _token = data['access_token'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('[AuthProvider] Login error: ${e.toString()}');
      _error = 'Login error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _profile = AuthProfile.initial();
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
