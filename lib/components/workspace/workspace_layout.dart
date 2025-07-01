import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/loading_spinner.dart';
import '../dynamic_renderer.dart';
import '../../state/project_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/web_socket_provider.dart';
import 'project_dropdown.dart';
import '../../config.dart';

class WorkspaceLayout extends StatefulWidget {
  final String? projectName;
  final String wsStatus;
  final String? wsError;
  final bool hasRootElement;

  const WorkspaceLayout({
    super.key,
    this.projectName,
    this.wsStatus = 'disconnected',
    this.wsError,
    this.hasRootElement = false,
  });

  @override
  State<WorkspaceLayout> createState() => _WorkspaceLayoutState();
}

class _WorkspaceLayoutState extends State<WorkspaceLayout> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Load projects only if they are not already loaded or being loaded
      if (projectProvider.projects.isEmpty && !projectProvider.isLoading && authProvider.token != null) {
        projectProvider.loadProjectsFromBackend(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final wsProvider = Provider.of<WebSocketProvider>(context);
    final hasProject = projectProvider.currentProject != null;
    final hasRootElement = wsProvider.uiState != null && wsProvider.uiState!['rootElement'] != null;

    // WebSocket connection logic
    if (hasProject && authProvider.token != null && !wsProvider.connected) {
      final wsUrl = '${AppConfig.wsBaseUrl}/stream/mcp:${projectProvider.currentProject!.id}?token=${authProvider.token}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        wsProvider.connect(url: wsUrl);
      });
    }
    if (!hasProject && wsProvider.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        wsProvider.disconnect();
      });
    }

    if (!hasProject) {
      return Scaffold(
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
    if (wsProvider.connected == false && hasProject) {
      if (wsProvider.error != null) {
        content = Center(
          child: Text('WebSocket error: ${wsProvider.error}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red)),
        );
      } else {
        content = LoadingSpinner(message: 'Connecting to WebSocket...');
      }
    } else if (wsProvider.connected && !hasRootElement) {
      content = const LoadingSpinner(message: 'Waiting for UI definition from server...');
    } else if (wsProvider.connected && hasRootElement) {
      content = DynamicRenderer(
        primitive: wsProvider.uiState!['rootElement'],
        sendAction: (msg) {
          wsProvider.send(msg);
        },
      );
    } else {
      // This else block might be unreachable now, but kept for safety.
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
    

    // Wrap the content in a SingleChildScrollView to prevent overflow.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10.0),
      child: content,
    );
  }
}