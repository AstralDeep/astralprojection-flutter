import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

class ImageUploadWidget extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(String?)? onValueChange;

  const ImageUploadWidget({
    required this.primitive,
    this.onValueChange,
    super.key,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isLoading = false;
  bool _isProcessed = false;
  String? _fileName;
  String? _error;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    // Initialize state from content prop, if available
    final content = widget.primitive['content']?.toString();
    if (content != null) {
      try {
        final parsed = jsonDecode(content);
        if (parsed['name'] != null) {
          setState(() {
            _fileName = parsed['name'];
            _isProcessed = true;
            // Note: We can't show a preview from just the name
          });
        }
      } catch (e) {
        // Ignore invalid content
      }
    }
  }

  void _handleClear() {
    setState(() {
      _isLoading = false;
      _isProcessed = false;
      _fileName = null;
      _error = null;
      _previewBytes = null;
    });
    widget.onValueChange?.call(null);
  }

  Future<void> _pickAndProcessImage() async {
    setState(() {
      _isLoading = true;
      _isProcessed = false;
      _error = null;
      _fileName = null;
      _previewBytes = null;
    });

    try {
      // 1. Pick an image file and read its bytes directly.
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null) {
        setState(() => _isLoading = false);
        return; // User canceled the picker
      }

      final file = result.files.single;
      final fileName = file.name;
      final Uint8List? fileBytes = file.bytes;

      if (fileBytes == null) {
        throw Exception("Failed to read image bytes.");
      }

      // Show preview immediately
      setState(() {
        _fileName = fileName;
        _previewBytes = fileBytes;
      });
      
      // 2. Check file size from config
      final maxFileSize = (widget.primitive['config']?['maxFileSize'] as num?)?.toInt();
      if (maxFileSize != null && file.size > maxFileSize) {
        final maxSizeMB = (maxFileSize / 1024 / 1024).toStringAsFixed(2);
        final fileSizeMB = (file.size / 1024 / 1024).toStringAsFixed(2);
        throw Exception('File is too large (${fileSizeMB}MB). Max size: ${maxSizeMB}MB.');
      }

      // 3. Encode to base64 and determine MIME type
      final base64String = base64Encode(fileBytes);
      final mimeType = lookupMimeType(fileName) ?? 'image/jpeg'; // Default to jpeg

      // 4. Create the data payload and notify the parent
      final fileData = {
        'base64': base64String,
        'name': fileName,
        'type': mimeType,
      };
      
      widget.onValueChange?.call(jsonEncode(fileData));

      // 5. Update UI state to show completion
      setState(() {
        _isProcessed = true;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _previewBytes = null; // Clear preview on error
      });
      widget.onValueChange?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    final label = config['label']?.toString() ?? 'Upload Image';
    final buttonLabel = config['buttonLabel']?.toString() ?? 'Select Image';
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
          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            label: Text(_isLoading ? 'Processing...' : buttonLabel),
            onPressed: _isLoading ? null : _pickAndProcessImage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _isProcessed ? Icons.check_circle : Icons.hourglass_top,
                  color: _isProcessed ? Colors.green : Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _handleClear,
                  child: Text(clearButtonLabel),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (_previewBytes != null) ...[
            const SizedBox(height: 12),
            Text("Preview:", style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Image.memory(
                  _previewBytes!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}