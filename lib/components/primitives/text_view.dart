import 'package:flutter/material.dart';

// --- TextView ---
class TextViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const TextViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] ?? primitive['config']?['initialText'] ?? '';
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final fontSize = (config['fontSize'] is num) ? (config['fontSize'] as num).toDouble() : 16.0;
    final fontWeightStr = config['fontWeight']?.toString() ?? 'normal';
    final variant = config['variant']?.toString();

    TextStyle style = TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeightStr == 'bold' ? FontWeight.bold : FontWeight.normal
    );

    if (variant == 'headline') {
        style = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: style.fontWeight) ?? style.copyWith(fontSize: 24);
    } else if (variant == 'titleSmall') {
        style = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: style.fontWeight) ?? style.copyWith(fontSize: 18);
    } else if (variant == 'caption') {
        style = Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: style.fontWeight, color: Colors.grey[600]) ?? style.copyWith(fontSize: 12, color: Colors.grey[600]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        content.toString(),
        style: style,
      ),
    );
  }
}