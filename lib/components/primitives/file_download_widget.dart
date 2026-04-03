import 'package:flutter/material.dart';

/// T046 - Renders a styled download button that dispatches a file_download event.
///
/// Schema: { type: "file_download", label: "Download Report",
///           url: "/api/files/report.pdf", filename: "report.pdf" }
class FileDownloadWidget extends StatelessWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const FileDownloadWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final label = component['label']?.toString() ?? 'Download';
    final url = component['url']?.toString() ?? '';
    final filename = component['filename']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextButton.icon(
        onPressed: () {
          sendEvent('file_download', {
            'url': url,
            if (filename.isNotEmpty) 'filename': filename,
          });
        },
        icon: const Icon(Icons.download),
        label: Text(label),
      ),
    );
  }
}
