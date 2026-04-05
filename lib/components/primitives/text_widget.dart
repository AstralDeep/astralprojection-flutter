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
    final backendStyle = component['style'] as Map<String, dynamic>? ?? {};
    final rawColor =
        component['color']?.toString() ?? backendStyle['color']?.toString();
    final textTheme = Theme.of(context).textTheme;

    var style = switch (variant) {
      'h1' => textTheme.headlineLarge,
      'h2' => textTheme.headlineMedium,
      'h3' => textTheme.headlineSmall,
      'caption' => textTheme.bodySmall?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600]),
      _ => textTheme.bodyMedium,
    };

    // Apply explicit color from backend if provided
    if (rawColor != null) {
      final parsed = _parseColor(rawColor);
      if (parsed != null) {
        style = style?.copyWith(color: parsed);
      }
    }

    // Apply fontSize from backend style
    final rawFontSize = backendStyle['fontSize']?.toString();
    if (rawFontSize != null) {
      final size = double.tryParse(rawFontSize.replaceAll('px', ''));
      if (size != null) {
        style = style?.copyWith(fontSize: size);
      }
    }

    // Apply fontWeight from backend style
    final rawFontWeight = backendStyle['fontWeight']?.toString();
    if (rawFontWeight != null) {
      final weight = _parseFontWeight(rawFontWeight);
      if (weight != null) {
        style = style?.copyWith(fontWeight: weight);
      }
    }

    // Parse textAlign from backend style
    final rawAlign = backendStyle['textAlign']?.toString();
    final textAlign = switch (rawAlign) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'left' => TextAlign.left,
      'justify' => TextAlign.justify,
      _ => null,
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
        child: Text(content, style: style, textAlign: textAlign),
      ),
    );
  }

  /// Parse a CSS font-weight value to Flutter FontWeight.
  static FontWeight? _parseFontWeight(String raw) {
    return switch (raw) {
      '100' => FontWeight.w100,
      '200' => FontWeight.w200,
      '300' => FontWeight.w300,
      '400' || 'normal' => FontWeight.w400,
      '500' => FontWeight.w500,
      '600' => FontWeight.w600,
      '700' || 'bold' => FontWeight.w700,
      '800' => FontWeight.w800,
      '900' => FontWeight.w900,
      _ => null,
    };
  }

  /// Parse a hex color string like "#FF0000" or "FF0000".
  static Color? _parseColor(String raw) {
    var hex = raw.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
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
