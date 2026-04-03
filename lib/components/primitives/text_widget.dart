import 'package:flutter/material.dart';

/// Renders text with variant styling.
///
/// Schema: { type: "text", content: "string", variant: "h1"|"h2"|"h3"|"body"|"caption" }
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
      _ => textTheme.bodyMedium, // 'body' and any unknown variant
    };

    return Semantics(
      label: content,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          content,
          style: style,
        ),
      ),
    );
  }
}
