import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config.dart';

class ProjectApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static final _logger = Logger();

  static Future<List<Map<String, dynamic>>> fetchProjects(String token, {int skip = 0, int limit = 100}) async {
    final url = Uri.parse('$baseUrl/projects/?skip=$skip&limit=$limit');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    // Debug print for Authorization header
    _logger.d('[ProjectApiService] Authorization header: Bearer $token');
    final response = await http.get(
      url,
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _logger.d('[ProjectApiService] Raw response data: ${data.toString()}');
      if (data is Map<String, dynamic> && data['projects'] is List) {
        // Also check for a current_project and set it if present
        final projects = List<Map<String, dynamic>>.from(data['projects']);
        // Optionally: handle current_project in ProjectProvider
        return projects;
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Malformed projects response: $data');
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed or token expired. Please log in again.');
    } else {
      throw Exception('Failed to load projects: ${response.statusCode}');
    }
  }
}
