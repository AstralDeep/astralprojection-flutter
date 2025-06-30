import 'package:flutter/material.dart';

// --- Button ---
class ButtonWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function()? onAction;
  const ButtonWidget({required this.primitive, this.onAction, super.key});

  @override
  Widget build(BuildContext context) {
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final label = config['label']?.toString() ?? primitive['label']?.toString() ?? 'Button';

    return ElevatedButton(
      onPressed: onAction,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}