import 'package:flutter/material.dart';

/// Renders a code block in a dark container with monospace font.
///
/// Schema: { type: "code", code: "print('hello')", language: "python", show_line_numbers: false }
class CodeWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const CodeWidget({required this.component, super.key});

  @override
  Widget build(BuildContext context) {
    final code = component['code'] as String? ?? '';
    final showLineNumbers = component['show_line_numbers'] as bool? ?? false;

    final String displayText;
    if (showLineNumbers) {
      final lines = code.split('\n');
      final gutterWidth = lines.length.toString().length;
      final buffer = StringBuffer();
      for (var i = 0; i < lines.length; i++) {
        final lineNum = (i + 1).toString().padLeft(gutterWidth);
        if (i > 0) buffer.write('\n');
        buffer.write('$lineNum  ${lines[i]}');
      }
      displayText = buffer.toString();
    } else {
      displayText = code;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: SelectableText(
          displayText,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13.0,
            color: Color(0xFFD4D4D4),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
