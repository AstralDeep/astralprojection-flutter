import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Renders a code block in a dark container with monospace font.
///
/// Schema: { type: "code", code: "print('hello')", language: "python", show_line_numbers: false }
class CodeWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const CodeWidget({required this.component, super.key});

  @override
  Widget build(BuildContext context) {
    final code = component['code'] as String? ?? '';
    final language = component['language']?.toString() ?? '';
    final showLineNumbers = component['show_line_numbers'] as bool? ?? false;

    final lines = code.split('\n');
    final gutterWidth = lines.length.toString().length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AstralColors.surface,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: AstralColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar with language label and copy button
            if (language.isNotEmpty || true)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: AstralColors.background.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: Row(
                  children: [
                    if (language.isNotEmpty)
                      Text(
                        language,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.0,
                          color: AstralColors.accent.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(4.0),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Copied to clipboard'),
                            backgroundColor: AstralColors.surface,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 14.0,
                          color: AstralColors.text.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Code body
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: showLineNumbers
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line-number gutter
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < lines.length; i++)
                                SizedBox(
                                  height: 20.0,
                                  child: Text(
                                    '${i + 1}'.padLeft(gutterWidth),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13.0,
                                      color:
                                          AstralColors.text.withValues(alpha: 0.25),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14.0),
                          // Code text
                          SelectableText(
                            code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13.0,
                              color: AstralColors.text,
                              height: 1.5,
                            ),
                          ),
                        ],
                      )
                    : SelectableText(
                        code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13.0,
                          color: AstralColors.text,
                          height: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
