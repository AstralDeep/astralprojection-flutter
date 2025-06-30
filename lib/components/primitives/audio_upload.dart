import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

// IMPORTANT: Replace this with your actual, full upload URL.
// Relative paths like '/api/...' will not work on mobile devices.
const String uploadUrl = 'https://CHANGE_THIS_WHOA.com/api/upload-file/mcp_audio';

class AudioUploadWidget extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(String?)? onValueChange;

  const AudioUploadWidget({
    required this.primitive,
    this.onValueChange,
    super.key,
  });

  @override
  State<AudioUploadWidget> createState() => _AudioUploadWidgetState();
}

class _AudioUploadWidgetState extends State<AudioUploadWidget> {
  // State reflecting the persistent value
  String? _fileName;
  bool _isUploaded = false;

  // Transient state for the UI and upload process
  String? _error;
  bool _isLoading = false;
  
  // State for the local file preview
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _previewPath;

  @override
  void initState() {
    super.initState();
    _updateStateFromPrimitive(widget.primitive);
  }

  @override
  void didUpdateWidget(AudioUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the primitive from the parent changes, update the state
    if (widget.primitive['content'] != oldWidget.primitive['content']) {
      _updateStateFromPrimitive(widget.primitive);
    }
  }

  void _updateStateFromPrimitive(Map<String, dynamic> primitive) {
    final content = primitive['content']?.toString();
    if (content != null && content.isNotEmpty) {
      try {
        final parsedContent = jsonDecode(content);
        if (parsedContent is Map && parsedContent['original_filename'] != null) {
          setState(() {
            _fileName = parsedContent['original_filename'];
            _isUploaded = true;
            _error = null;
          });
          return;
        }
      } catch (e) {
        // Fall through if JSON is invalid
      }
    }
    
    // Clear state if content is null or invalid, but only if a file isn't already being previewed
    if (_previewPath == null) {
      _clearSelection(notifyParent: false); // Don't notify parent on initial load
    }
  }
  
  void _clearSelection({bool notifyParent = true}) {
    _audioPlayer.stop();
    setState(() {
      _fileName = null;
      _error = null;
      _isUploaded = false;
      _isLoading = false;
      _previewPath = null;
    });
    if (notifyParent && widget.onValueChange != null) {
      widget.onValueChange!(null);
    }
  }

  Future<void> _pickAndUploadFile() async {
    // 1. Reset state for the new upload
    setState(() {
      _isLoading = true;
      _error = null;
      _isUploaded = false;
    });

    try {
      // 2. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result == null || result.files.single.path == null) {
        setState(() => _isLoading = false);
        return; // User canceled the picker
      }

      final pickedFile = result.files.single;
      final file = File(pickedFile.path!);

      // Update UI with selected file name and prepare preview
      setState(() {
        _fileName = pickedFile.name;
        _previewPath = pickedFile.path;
      });
      await _audioPlayer.setFilePath(pickedFile.path!);

      // 3. (Optional) Validate file size from config
      final maxFileSize = (widget.primitive['config']?['maxFileSize'] as num?)?.toInt();
      if (maxFileSize != null && await file.length() > maxFileSize) {
        final maxSizeMB = (maxFileSize / 1024 / 1024).toStringAsFixed(2);
        final fileSizeMB = (await file.length() / 1024 / 1024).toStringAsFixed(2);
        setState(() {
          _error = 'File is too large (${fileSizeMB}MB). Max size: ${maxSizeMB}MB.';
          _isLoading = false;
        });
        return;
      }

      // 4. Upload the file
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..files.add(await http.MultipartFile.fromPath('file', pickedFile.path!));
      var response = await request.send();

      // 5. Handle the response
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        if (widget.onValueChange != null) {
            widget.onValueChange!(responseBody);
        }
        final responseData = jsonDecode(responseBody);
        setState(() {
          _isUploaded = true;
          _fileName = responseData['original_filename'] ?? pickedFile.name;
          _isLoading = false;
        });
      } else {
        final responseData = jsonDecode(responseBody);
        setState(() {
          _error = responseData['error'] ?? 'Upload failed with status: ${response.statusCode}';
          _isLoading = false;
        });
        if (widget.onValueChange != null) {
          widget.onValueChange!(null);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
       if (widget.onValueChange != null) {
          widget.onValueChange!(null);
        }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    final label = config['label']?.toString() ?? 'Upload Audio';
    final buttonLabel = config['buttonLabel']?.toString() ?? 'Select Audio File';
    final clearButtonLabel = config['clearButtonLabel']?.toString() ?? 'Clear';

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty)
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.audiotrack),
              label: Text(_isLoading ? 'Uploading...' : buttonLabel),
              onPressed: _isLoading ? null : _pickAndUploadFile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _isUploaded ? Icons.check_circle : (_error != null ? Icons.error : Icons.music_note),
                  color: _isUploaded ? Colors.green : (_error != null ? Colors.red : Colors.grey.shade700),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName!,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: _isUploaded ? Colors.green : (_error != null ? Colors.red : Colors.black87),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isLoading ? null : _clearSelection,
                  child: Text(clearButtonLabel),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (_previewPath != null && _error == null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const Text("Preview", style: TextStyle(fontWeight: FontWeight.bold)),
            _AudioPlayerControls(player: _audioPlayer),
          ],
        ],
      ),
    );
  }
}

// A simple helper widget to provide playback controls for the preview
class _AudioPlayerControls extends StatelessWidget {
  final AudioPlayer player;
  const _AudioPlayerControls({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
          return const Center(child: CircularProgressIndicator());
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(playing == true ? Icons.pause_circle_filled : Icons.play_circle_filled),
              iconSize: 48.0,
              onPressed: () {
                if (playing == true) {
                  player.pause();
                } else {
                  if (player.processingState == ProcessingState.completed) {
                     player.seek(Duration.zero);
                  }
                  player.play();
                }
              },
            ),
            Expanded(
              child: StreamBuilder<Duration?>(
                stream: player.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, positionSnapshot) {
                      var position = positionSnapshot.data ?? Duration.zero;
                      if (position > duration) {
                        position = duration;
                      }
                      return Slider(
                        min: 0.0,
                        max: duration.inMilliseconds.toDouble(),
                        value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                        onChanged: (value) {
                          player.seek(Duration(milliseconds: value.round()));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}