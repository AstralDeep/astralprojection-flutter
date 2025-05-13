import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/loading_spinner.dart';
import '../dynamic_renderer.dart';
import '../../state/project_provider.dart';
import '../../state/auth_provider.dart';
import 'project_dropdown.dart';

class WorkspaceLayout extends StatelessWidget {
  final String? projectName;
  final String wsStatus; // 'connecting', 'reconnecting', 'connected', 'error', etc.
  final String? wsError;
  final bool hasRootElement; // Simulates if UI definition is loaded

  const WorkspaceLayout({
    Key? key,
    this.projectName,
    this.wsStatus = 'disconnected',
    this.wsError,
    this.hasRootElement = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context); // listen: true (default)
    final hasProject = projectProvider.currentProject != null;

    if (!hasProject) {
      // Debug: print current project and projects
      debugPrint('[WorkspaceLayout] (build) currentProject: ' + (projectProvider.currentProject != null ? '{id: ' + projectProvider.currentProject!.id + ', name: ' + projectProvider.currentProject!.name + '}' : 'null'));
      debugPrint('[WorkspaceLayout] (build) projects: ' + projectProvider.projects.map((p) => '{id: ' + p.id + ', name: ' + p.name + '}').toList().toString());

      // Auto-load projects if not already loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        debugPrint('[WorkspaceLayout] authProvider.token: \'${authProvider.token}\'');
        if (projectProvider.projects.isEmpty && !projectProvider.isLoading && authProvider.token != null) {
          projectProvider.loadProjectsFromBackend(authProvider.token!);
        }
        debugPrint('[WorkspaceLayout] projectProvider.projects: ' + projectProvider.projects.map((p) => '{id: ' + p.id + ', name: ' + p.name + '}').toList().toString());
        debugPrint('[WorkspaceLayout] projectProvider.currentProject: ' + (projectProvider.currentProject != null ? '{id: ' + projectProvider.currentProject!.id + ', name: ' + projectProvider.currentProject!.name + '}' : 'null'));
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'AI Interface',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5CF0),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              onPressed: () {},
              tooltip: 'Settings',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: const Text(
                  'P',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProjectDropdown(),
              const SizedBox(height: 32),
              Text(
                'Select a project to begin.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF7F9FB),
      );
    }

    Widget content;
    if (wsStatus == 'connecting' || wsStatus == 'reconnecting') {
      content = LoadingSpinner(message: 'Connecting to ${projectName ?? 'project'}...');
    } else if (wsStatus != 'connected') {
      final errorText = wsStatus == 'error' ? (wsError ?? 'Connection error.') : 'Attempting to reconnect...';
      content = Center(
        child: Text('Disconnected. $errorText', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    } else if (!hasRootElement) {
      content = const LoadingSpinner(message: 'Waiting for UI definition from server...');
    } else {
      content = DynamicRenderer(primitive: {'type': 'StackLayout', 'id': 'root'});
    }
    return Container(
      padding: const EdgeInsets.all(10.0),
      height: double.infinity,
      width: double.infinity,
      child: content,
    );
  }
}
