import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dynamic_renderer.dart';
import '../../state/project_provider.dart';
import '../../state/auth_provider.dart';
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
  final TextEditingController _chatController = TextEditingController();

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (projectProvider.projects.isEmpty &&
        !projectProvider.isLoading &&
        authProvider.token != null) {
      projectProvider.loadProjectsFromBackend(authProvider.token!);
    }
  }

  void _wireThemeCallback() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    ws.onThemeReceived = (config) => themeProvider.applyBackendTheme(config);
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  /// Send a chat message via WebSocket (T065).
  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    wsProvider.sendEvent('chat_message', {'text': text, 'chat_id': 'default'});
    _chatController.clear();
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
      if (targetId != null) 'target_id': targetId,
    });
  }

  void _connectIfNeeded() {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    final deviceProfile =
        Provider.of<DeviceProfileProvider>(context, listen: false);
    final hasProject = projectProvider.currentProject != null;

    if (hasProject && authProvider.token != null && !wsProvider.connected) {
      if (!_wsConnectScheduled) {
        _wsConnectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _wsConnectScheduled = false;
          wsProvider.connect(
            token: authProvider.token!,
            device: deviceProfile.toDeviceMap(),
            capabilities: supportedCapabilities,
            projectId: projectProvider.currentProject!.id,
          );
        });
      }
    }
    if (!hasProject && wsProvider.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        wsProvider.disconnect();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final wsProvider = Provider.of<WebSocketProvider>(context);
    final hasProject = projectProvider.currentProject != null;

    _connectIfNeeded();

    // No project selected — show project dropdown
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

    // Connection error
    if (!wsProvider.connected && wsProvider.error != null) {
      return Center(
        child: Text(
          'WebSocket error: ${wsProvider.error}',
          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
        ),
      );
    }

    // Show SDUI tree (live or cached) with chat input bar at the bottom.
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
          _buildChatInputBar(),
        ],
      );
    }

    // Connecting — the LoadingOverlay in app.dart handles the visual
    return const SizedBox.shrink();
  }

  /// Chat input bar pinned to the bottom of the workspace (T065).
  Widget _buildChatInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendChatMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendChatMessage,
              tooltip: 'Send message',
            ),
          ],
        ),
      ),
    );
  }
}
