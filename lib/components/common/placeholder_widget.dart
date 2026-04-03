import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Rendered for any SDUI component type the client does not recognize.
class PlaceholderWidget extends StatelessWidget {
  static final _logger = Logger();
  final String componentType;
  final String? componentId;

  const PlaceholderWidget({
    super.key,
    required this.componentType,
    this.componentId,
  });

  @override
  Widget build(BuildContext context) {
    _logger.w('Unknown SDUI component type: "$componentType" (id: $componentId)');
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(4),
        color: Colors.orange.withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unknown component: "$componentType"',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
