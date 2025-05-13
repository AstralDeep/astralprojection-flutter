import 'package:flutter/material.dart';

/// Placeholder for a dynamic renderer that would render UI primitives from a backend definition.
/// In a real implementation, this would use a registry of widgets and recursively build the UI tree.
class DynamicRenderer extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function(Map<String, dynamic> message)? sendAction;

  const DynamicRenderer({
    Key? key,
    required this.primitive,
    this.sendAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For now, just display the primitive type and ID as a placeholder
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DynamicRenderer Placeholder',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Type: ${primitive['type'] ?? 'unknown'}'),
          Text('ID: ${primitive['id'] ?? 'unknown'}'),
        ],
      ),
    );
  }
}
