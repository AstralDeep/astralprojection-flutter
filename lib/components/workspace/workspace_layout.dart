import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dynamic_renderer.dart';
import '../../state/project_provider.dart';
import '../../state/token_storage_provider.dart';
import '../../state/web_socket_provider.dart';
import '../../state/device_profile_provider.dart';
import '../../state/theme_provider.dart';
import '../../services/voice_input_service.dart';
import '../../services/voice_output_service.dart';
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
  VoiceInputService? _voiceInput;
  VoiceOutputService? _voiceOutput;
  bool _isRecording = false;
  bool _speakerEnabled = true;

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

  @override
  void dispose() {
    _chatController.dispose();
    _voiceInput?.dispose();
    _voiceOutput?.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _voiceInput?.stopStreaming();
      setState(() => _isRecording = false);
    } else {
      _voiceInput ??= VoiceInputService();
      _voiceInput!.startStreaming().then((_) {
        setState(() => _isRecording = true);
      });
      _voiceInput!.transcripts.listen((transcript) {
        _chatController.text += transcript;
      });
    }
  }

  void _toggleSpeaker() {
    setState(() => _speakerEnabled = !_speakerEnabled);
  }

  void _playTtsAudio(String url) {
    if (!_speakerEnabled) return;
    _voiceOutput ??= VoiceOutputService();
    _voiceOutput!.playAudio(url);
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
    // Don't disconnect the initial WS connection — it receives
    // the login page and dashboard SDUI from the backend.
    // Only disconnect when switching away from a project-specific stream.
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final wsProvider = Provider.of<WebSocketProvider>(context);
    final hasProject = projectProvider.currentProject != null;

    _connectIfNeeded();

    // SDUI content from backend takes priority — render login page,
    // dashboard, or any server-driven UI regardless of project state.
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

  /// Chat input bar pinned to the bottom of the workspace.
  /// Includes voice mic + speaker toggle (hidden on TV per DeviceProfile).
  Widget _buildChatInputBar() {
    final dp = Provider.of<DeviceProfileProvider>(context);
    final hasMic = dp.deviceType != 'tv';

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
            // Voice mic button — hidden on TV (no microphone)
            if (hasMic)
              IconButton(
                key: ValueKey('mic_$_isRecording'),
                icon: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: _isRecording ? Colors.redAccent : null,
                ),
                onPressed: _toggleRecording,
                tooltip: _isRecording ? 'Stop recording' : 'Voice input',
              ),
            // Speaker toggle — hidden on TV
            if (hasMic)
              IconButton(
                key: ValueKey('speaker_$_speakerEnabled'),
                icon: Icon(
                  _speakerEnabled ? Icons.volume_up : Icons.volume_off,
                ),
                onPressed: _toggleSpeaker,
                tooltip: _speakerEnabled ? 'Mute TTS' : 'Unmute TTS',
              ),
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
