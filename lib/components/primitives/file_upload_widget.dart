import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// T045 - Renders a file upload button that opens the platform file picker.
///
/// Schema: { type: "file_upload", label: "Upload File",
///           accept: "*/*", action: "upload_handler" }
class FileUploadWidget extends StatefulWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const FileUploadWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  bool _isPicking = false;
  String? _selectedFileName;

  /// Maps a MIME-style accept string to [FileType] and allowed extensions.
  ({FileType type, List<String>? extensions}) _resolveFileType() {
    final accept = widget.component['accept']?.toString() ?? '*/*';

    if (accept == '*/*' || accept.isEmpty) {
      return (type: FileType.any, extensions: null);
    }

    // Support comma-separated extension lists like ".pdf,.docx"
    if (accept.contains('.')) {
      final extensions = accept
          .split(',')
          .map((e) => e.trim().replaceFirst('.', ''))
          .where((e) => e.isNotEmpty)
          .toList();
      if (extensions.isNotEmpty) {
        return (type: FileType.custom, extensions: extensions);
      }
    }

    // Support broad MIME categories
    if (accept.startsWith('image/')) {
      return (type: FileType.image, extensions: null);
    }
    if (accept.startsWith('video/')) {
      return (type: FileType.video, extensions: null);
    }
    if (accept.startsWith('audio/')) {
      return (type: FileType.audio, extensions: null);
    }

    return (type: FileType.any, extensions: null);
  }

  Future<void> _pickFile() async {
    if (_isPicking) return;

    setState(() => _isPicking = true);

    try {
      final fileConfig = _resolveFileType();

      final result = await FilePicker.pickFiles(
        type: fileConfig.type,
        allowedExtensions: fileConfig.extensions,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled the picker.
        setState(() => _isPicking = false);
        return;
      }

      final file = result.files.single;
      final action =
          widget.component['action']?.toString() ?? 'upload_handler';

      setState(() {
        _selectedFileName = file.name;
        _isPicking = false;
      });

      widget.sendEvent(action, {
        'filename': file.name,
        'size': file.size,
      });
    } catch (_) {
      setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.component['label']?.toString() ?? 'Upload File';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: _isPicking ? null : _pickFile,
            icon: _isPicking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(label),
          ),
          if (_selectedFileName != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _selectedFileName!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
