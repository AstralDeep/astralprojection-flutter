import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Represents a project entity with an ID and name.
class Project {
  final String id;
  final String name;
  // Add other fields as needed

  Project({required this.id, required this.name});
}

/// Provides project list, current project, and connection status management.
class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  Project? _currentProject;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _error;
  ConnectionStatus _projectConnectionStatus = ConnectionStatus.disconnected;
  String? _projectConnectionError;
  final _logger = Logger();

  List<Project> get projects => _projects;
  Project? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get error => _error;
  ConnectionStatus get projectConnectionStatus => _projectConnectionStatus;
  String? get projectConnectionError => _projectConnectionError;

  /// Sets the connection status for the current project.
  void setProjectConnectionStatus(ConnectionStatus status, [String? error]) {
    if (status != _projectConnectionStatus || error != _projectConnectionError) {
      _projectConnectionStatus = status;
      _projectConnectionError = error;
      notifyListeners();
    }
  }

  /// Sets the initial project if none is currently selected.
  void setInitialProject(Project project) {
    if (project.id.isNotEmpty && _currentProject == null) {
      _currentProject = project;
      _error = null;
      _projectConnectionStatus = ConnectionStatus.disconnected;
      _projectConnectionError = null;
      notifyListeners();
    }
  }

  /// Loads projects from the backend using the provided token.
  /// Currently a no-op — projects API not yet implemented; chats are standalone.
  Future<void> loadProjectsFromBackend(String token) async {
    _isLoading = false;
    _error = null;
    notifyListeners();
    return;
    // ignore: dead_code
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Fetch the full response so we can access current_project
      final url = Uri.parse('${AppConfig.apiBaseUrl}/projects/?skip=0&limit=100');
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };
      final response = await http.get(url, headers: headers);
      final data = json.decode(response.body);
      _logger.d('[ProjectProvider] Raw backend response: $data');
      if (data is Map<String, dynamic> && data['projects'] is List) {
        _projects = List<Map<String, dynamic>>.from(data['projects'])
            .map((p) => Project(id: p['id'].toString(), name: p['name'] ?? 'Unnamed Project'))
            .toList();
        _logger.d('[ProjectProvider] _projects after mapping: ${_projects.map((p) => '{id: ${p.id}, name: ${p.name}}').toList()}');
        if (data['current_project'] != null) {
          final cp = data['current_project'];
          _currentProject = Project(id: cp['id'].toString(), name: cp['name'] ?? 'Unnamed Project');
          _projectConnectionStatus = ConnectionStatus.connected;
        } else if (_currentProject == null && _projects.isNotEmpty) {
          _setCurrentProjectAndResetState(_projects[0]);
          _projectConnectionStatus = ConnectionStatus.connected;
        }
      } else {
        _error = 'Malformed projects response: $data';
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the current project and resets the state.
  void _setCurrentProjectAndResetState(Project project) {
    if (_currentProject?.id != project.id) {
      _currentProject = project;
      _error = null;
      _projectConnectionStatus = ConnectionStatus.disconnected;
      _projectConnectionError = null;
      // TODO: Reset view state if needed
      notifyListeners();
    }
  }

  /// Switches to a different project by its ID.
  Future<void> switchProject(String projectId) async {
    if (_currentProject?.id == projectId) return;
    _isLoadingDetails = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500)); // TODO: Replace with real API call
    final project = _projects.firstWhere((p) => p.id == projectId, orElse: () => Project(id: projectId, name: 'Unknown Project'));
    _setCurrentProjectAndResetState(project);
    _isLoadingDetails = false;
    notifyListeners();
  }

  /// Resets the provider state to its initial values.
  void reset() {
    _projects = [];
    _currentProject = null;
    _isLoading = false;
    _isLoadingDetails = false;
    _error = null;
    _projectConnectionStatus = ConnectionStatus.disconnected;
    _projectConnectionError = null;
    // TODO: Reset view state if needed
    notifyListeners();
  }
}
