import 'package:flutter/material.dart';

// --- CodeView ---
class CodeViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const CodeViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content']?.toString() ?? '';
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: SelectableText(
        content,
        style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
      ),
    );
  }
}