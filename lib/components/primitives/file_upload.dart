import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

class FileUploadFieldWidget extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(String?)? onValueChange;

  const FileUploadFieldWidget({
    required this.primitive,
    this.onValueChange,
    super.key,
  });

  @override
  State<FileUploadFieldWidget> createState() => _FileUploadFieldWidgetState();
}

class _FileUploadFieldWidgetState extends State<FileUploadFieldWidget> {
  bool _isLoading = false;
  String? _fileName;
  String? _error;

  Future<void> _pickAndProcessFile() async {
    setState(() {
      _isLoading = true;
      _fileName = null;
      _error = null;
    });

    try {
      // 1. Pick the file and read its bytes directly.
      // This works on both web and mobile.
      final result = await FilePicker.pickFiles(withData: true);

      if (result == null) {
        setState(() => _isLoading = false);
        return; // User canceled the picker
      }

      final file = result.files.single;
      final fileName = file.name;
      final Uint8List? fileBytes = file.bytes;

      if (fileBytes == null) {
        throw Exception("Failed to read file bytes.");
      }
      
      // 2. Encode to base64 and determine MIME type
      final base64String = base64Encode(fileBytes);
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

      // 3. Create the data payload and notify the parent
      final fileData = {
        'base64': base64String,
        'name': fileName,
        'type': mimeType,
      };
      
      widget.onValueChange?.call(jsonEncode(fileData));

      // 4. Update UI state
      setState(() {
        _fileName = fileName;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = "Failed to process file: $e";
        _isLoading = false;
      });
      widget.onValueChange?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    final label = config['label']?.toString() ?? 'Choose File';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _pickAndProcessFile,
                child: Text(label),
              ),
              const SizedBox(width: 16),
              if (_isLoading)
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text("Processing..."),
                  ],
                ),
              if (_fileName != null)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }
}