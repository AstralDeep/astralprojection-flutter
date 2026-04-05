import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dynamic_renderer.dart';
import '../chat/chat_input_bar.dart';
import '../theme/app_theme.dart';
import '../../state/app_shell_provider.dart';
import '../../state/project_provider.dart';
import '../../state/token_storage_provider.dart';
import '../../state/web_socket_provider.dart';
import '../../state/device_profile_provider.dart';
import '../../state/theme_provider.dart';
import 'project_dropdown.dart';
import 'saved_components_drawer.dart';

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
  bool _drawerOpen = false;

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

  /// Save a rendered SDUI component to the drawer (T015/T016).
  void _saveComponentToDrawer(
      Map<String, dynamic> component, AppShellProvider shell) {
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    final chatId = shell.activeChatId ?? 'default';
    final type = component['type'] as String? ?? 'unknown';
    final title = component['title'] as String? ??
        component['label'] as String? ??
        type;
    wsProvider.sendEvent('save_component', {
      'chat_id': chatId,
      'component_data': component,
      'component_type': type,
      'title': title,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "$title" to drawer'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Send a save_component action (T066).
  void saveComponent(Map<String, dynamic> componentData) {
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    wsProvider.sendEvent('save_component', componentData);
  }

  /// Send a combine_components action — uses source_id/target_id per backend contract.
  void combineComponents(String sourceId, String targetId) {
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    wsProvider.sendEvent('combine_components', {
      'source_id': sourceId,
      'target_id': targetId,
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

    final shell = Provider.of<AppShellProvider>(context);

    final hasSaved = wsProvider.savedComponents?.isNotEmpty ?? false;

    // SDUI content from backend takes priority
    if (wsProvider.components.isNotEmpty) {
      return Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final component in wsProvider.components)
                        _SaveableComponent(
                          component: component,
                          onSave: () =>
                              _saveComponentToDrawer(component, shell),
                        ),
                    ],
                  ),
                ),
              ),
              _ChatStatusIndicator(
                status: shell.chatStatus,
                message: shell.chatStatusMessage,
              ),
              const ChatInputBar(),
            ],
          ),
          // Right-edge drawer indicator (T032)
          if (hasSaved && !_drawerOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _drawerOpen = true),
                  child: Container(
                    width: 24,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AstralColors.primary.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.chevron_left,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          // Full-screen drawer overlay (T033)
          if (_drawerOpen)
            Positioned.fill(
              child: Material(
                color: AstralColors.background.withValues(alpha: 0.95),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: AstralColors.text),
                        onPressed: () => setState(() => _drawerOpen = false),
                      ),
                    ),
                    const Expanded(child: SavedComponentsDrawer()),
                  ],
                ),
              ),
            ),
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

/// Animated status indicator shown above the chat input during processing.
class _ChatStatusIndicator extends StatelessWidget {
  final String status;
  final String message;

  const _ChatStatusIndicator({required this.status, required this.message});

  @override
  Widget build(BuildContext context) {
    if (status == 'idle' || status == 'done') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AstralColors.surface.withValues(alpha: 0.9),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AstralColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.isNotEmpty ? message : _defaultLabel(status),
              style: const TextStyle(
                fontSize: 13,
                color: AstralColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _defaultLabel(String status) {
    switch (status) {
      case 'thinking':
        return 'Thinking...';
      case 'executing':
        return 'Executing...';
      case 'fixing':
        return 'Fixing...';
      default:
        return 'Processing...';
    }
  }
}

/// Wraps a rendered SDUI component with a persistent "+" save button overlay.
class _SaveableComponent extends StatefulWidget {
  final Map<String, dynamic> component;
  final VoidCallback onSave;

  const _SaveableComponent({required this.component, required this.onSave});

  @override
  State<_SaveableComponent> createState() => _SaveableComponentState();
}

class _SaveableComponentState extends State<_SaveableComponent> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        children: [
          DynamicRenderer(component: widget.component),
          Positioned(
            top: 4,
            right: 4,
            child: AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: widget.onSave,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AstralColors.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
