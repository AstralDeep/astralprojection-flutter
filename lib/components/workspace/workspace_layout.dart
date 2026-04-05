import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dynamic_renderer.dart';
import '../chat/chat_input_bar.dart';
import '../../state/project_provider.dart';
import '../../state/token_storage_provider.dart';
import '../../state/web_socket_provider.dart';
import '../../state/device_profile_provider.dart';
import '../../state/theme_provider.dart';
import 'project_dropdown.dart';

/// Main workspace that renders the SDUI component tree from the backend.
///
/// Manages WebSocket connection lifecycle, shows cached SDUI tree on restart,
/// and wires theme updates from the backend to ThemeProvider.
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
  bool _wsConnectScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjects();
      _wireThemeCallback();
    });
  }

  void _loadProjects() {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final tokenStorage =
        Provider.of<TokenStorageProvider>(context, listen: false);
    if (projectProvider.projects.isEmpty &&
        !projectProvider.isLoading &&
        tokenStorage.hasToken) {
      projectProvider.loadProjectsFromBackend(tokenStorage.token!);
    }
  }

  void _wireThemeCallback() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    ws.onThemeReceived = (config) => themeProvider.applyBackendTheme(config);
  }

  /// Send a save_component action (T066).
  void saveComponent(Map<String, dynamic> componentData) {
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    wsProvider.sendEvent('save_component', componentData);
  }

  /// Send a combine_components action (T066).
  void combineComponents(List<String> componentIds, {String? targetId}) {
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    wsProvider.sendEvent('combine_components', {
      'component_ids': componentIds,
      'target_id': ?targetId,
    });
  }

  void _connectIfNeeded() {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final tokenStorage =
        Provider.of<TokenStorageProvider>(context, listen: false);
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    final deviceProfile =
        Provider.of<DeviceProfileProvider>(context, listen: false);
    final hasProject = projectProvider.currentProject != null;

    if (hasProject && !wsProvider.connected) {
      if (!_wsConnectScheduled) {
        _wsConnectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _wsConnectScheduled = false;
          wsProvider.connect(
            token: tokenStorage.token,
            device: deviceProfile.toDeviceMap(),
            capabilities: supportedCapabilities,
            projectId: projectProvider.currentProject!.id,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final wsProvider = Provider.of<WebSocketProvider>(context);
    final hasProject = projectProvider.currentProject != null;

    _connectIfNeeded();

    // SDUI content from backend takes priority
    if (wsProvider.components.isNotEmpty) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final component in wsProvider.components)
                    DynamicRenderer(component: component),
                ],
              ),
            ),
          ),
          const ChatInputBar(),
        ],
      );
    }

    // Connection error
    if (!wsProvider.connected && wsProvider.error != null) {
      return Center(
        child: Text(
          'WebSocket error: ${wsProvider.error}',
          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
        ),
      );
    }

    // No SDUI content and no project — show project dropdown
    if (!hasProject) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ProjectDropdown(),
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
      );
    }

    // Connecting — the LoadingOverlay in app.dart handles the visual
    return const SizedBox.shrink();
  }
}
