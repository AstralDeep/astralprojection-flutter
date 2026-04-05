import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_shell_provider.dart';
import '../../state/device_profile_provider.dart';
import '../../state/web_socket_provider.dart';
import '../../services/voice_input_service.dart';
import '../../services/voice_output_service.dart';
import '../theme/app_theme.dart';

/// Polished chat input bar with paperclip, mic, volume, and send button.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  VoiceInputService? _voiceInput;
  VoiceOutputService? _voiceOutput;
  bool _isRecording = false;
  bool _speakerEnabled = true;
  String? _attachedFileName;
  bool _isPickingFile = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _voiceInput?.dispose();
    _voiceOutput?.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final shell = Provider.of<AppShellProvider>(context, listen: false);
    ws.sendEvent('chat_message', {
      'text': text,
      'chat_id': shell.activeChatId ?? 'default',
    });
    _controller.clear();
    setState(() => _attachedFileName = null);
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
        _controller.text += transcript;
      });
    }
  }

  void _toggleSpeaker() {
    setState(() => _speakerEnabled = !_speakerEnabled);
  }

  Future<void> _pickFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'json', 'md', 'pdf', 'png', 'jpg'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _attachedFileName = result.files.first.name);
      }
    } finally {
      setState(() => _isPickingFile = false);
    }
  }

  String _getPlaceholder() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final shell = Provider.of<AppShellProvider>(context, listen: false);
    if (!ws.connected) return 'Connecting to orchestrator...';
    if (_isRecording) return 'Listening...';
    if (shell.chatStatus == 'thinking') return 'Agent is thinking...';
    if (shell.chatStatus == 'executing') return 'Agent is executing...';
    return 'Ask anything or attach a file...';
  }

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DeviceProfileProvider>(context);
    final ws = Provider.of<WebSocketProvider>(context);
    final hasMic = dp.deviceType != 'tv';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AstralColors.background.withValues(alpha: 0.8),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording indicator
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Recording your voice...',
                        style:
                            TextStyle(fontSize: 11, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),

            // Attached file indicator
            if (_attachedFileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AstralColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AstralColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file,
                          size: 14, color: AstralColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _attachedFileName!,
                          style: const TextStyle(
                              fontSize: 12, color: AstralColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _attachedFileName = null),
                        child: Icon(Icons.close,
                            size: 14,
                            color:
                                AstralColors.primary.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ),

            // Main input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Input container (paperclip + text + mic + speaker)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AstralColors.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Paperclip
                        _InputIcon(
                          icon: _isPickingFile
                              ? Icons.hourglass_empty
                              : Icons.attach_file,
                          tooltip: 'Attach File',
                          onPressed: _pickFile,
                          color: AstralColors.text.withValues(alpha: 0.4),
                        ),

                        // Text input
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: const TextStyle(
                                fontSize: 14, color: AstralColors.text),
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: _getPlaceholder(),
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color:
                                    AstralColors.text.withValues(alpha: 0.3),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            enabled: ws.connected,
                          ),
                        ),

                        // Mic button
                        if (hasMic)
                          _InputIcon(
                            icon: _isRecording ? Icons.stop : Icons.mic_none,
                            tooltip:
                                _isRecording ? 'Stop recording' : 'Voice input',
                            onPressed: _toggleRecording,
                            color: _isRecording
                                ? Colors.redAccent
                                : AstralColors.text.withValues(alpha: 0.4),
                            backgroundColor: _isRecording
                                ? Colors.red.withValues(alpha: 0.2)
                                : null,
                          ),

                        // Speaker toggle
                        if (hasMic)
                          _InputIcon(
                            icon: _speakerEnabled
                                ? Icons.volume_up
                                : Icons.volume_off,
                            tooltip: _speakerEnabled
                                ? 'Disable voice output'
                                : 'Enable voice output',
                            onPressed: _toggleSpeaker,
                            color: _speakerEnabled
                                ? AstralColors.primary
                                : AstralColors.text.withValues(alpha: 0.4),
                            backgroundColor: _speakerEnabled
                                ? AstralColors.primary.withValues(alpha: 0.15)
                                : null,
                          ),

                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button (outside input container)
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AstralColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small icon button used inside the chat input container.
class _InputIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;
  final Color? backgroundColor;

  const _InputIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
    this.backgroundColor,
  });

  @override
  State<_InputIcon> createState() => _InputIconState();
}

class _InputIconState extends State<_InputIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: widget.backgroundColor ??
                  (_hovered
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon,
                size: 20,
                color: _hovered
                    ? AstralColors.text
                    : widget.color),
          ),
        ),
      ),
    );
  }
}
