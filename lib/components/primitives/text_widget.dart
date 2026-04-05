import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders text with variant styling, supporting markdown and LaTeX math.
///
/// Schema: { type: "text", content: "string", variant: "h1"|"h2"|"h3"|"body"|"caption" }
///
/// LaTeX support: Inline math delimited by `$...$` and block math by `$$...$$`
/// are rendered using flutter_math_fork within flutter_markdown.
class TextWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const TextWidget({
    required this.component,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = component['content']?.toString() ?? '';
    final variant = component['variant']?.toString() ?? 'body';
    final textTheme = Theme.of(context).textTheme;

    final style = switch (variant) {
      'h1' => textTheme.headlineLarge,
      'h2' => textTheme.headlineMedium,
      'h3' => textTheme.headlineSmall,
      'caption' => textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      _ => textTheme.bodyMedium,
    };

    // Check if content contains markdown or LaTeX indicators
    final hasMarkdown = content.contains('**') ||
        content.contains('*') ||
        content.contains('`') ||
        content.contains('#') ||
        content.contains('[') ||
        content.contains('\n');
    final hasLatex = content.contains(r'$');

    if (hasLatex) {
      return Semantics(
        label: content,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildLatexContent(context, content, style),
        ),
      );
    }

    if (hasMarkdown) {
      return Semantics(
        label: content,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(p: style),
            selectable: true,
          ),
        ),
      );
    }

    return Semantics(
      label: content,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(content, style: style),
      ),
    );
  }

  /// Build content with inline/block LaTeX math expressions.
  ///
  /// Splits on `$$...$$` (block) and `$...$` (inline), rendering
  /// math segments with flutter_math_fork and text segments with
  /// flutter_markdown.
  Widget _buildLatexContent(
      BuildContext context, String content, TextStyle? style) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);
    int lastEnd = 0;

    for (final match in regex.allMatches(content)) {
      // Text before this match
      if (match.start > lastEnd) {
        final text = content.substring(lastEnd, match.start);
        spans.add(TextSpan(text: text, style: style));
      }

      final blockMath = match.group(1);
      final inlineMath = match.group(2);
      final mathExpr = blockMath ?? inlineMath ?? '';
      final isBlock = blockMath != null;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: isBlock
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Math.tex(
                  mathExpr,
                  textStyle: style,
                  mathStyle: MathStyle.display,
                ),
              )
            : Math.tex(
                mathExpr,
                textStyle: style?.copyWith(fontSize: (style.fontSize ?? 14)),
                mathStyle: MathStyle.text,
              ),
      ));
      lastEnd = match.end;
    }

    // Remaining text after last match
    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd), style: style));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
