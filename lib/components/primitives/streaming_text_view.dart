import 'package:flutter/material.dart';

// --- StreamingTextView ---
class StreamingTextViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const StreamingTextViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectableText(content),
    );
  }
}