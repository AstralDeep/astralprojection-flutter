import 'dart:ui';
import 'package:flutter/material.dart';
import '../dynamic_renderer.dart';
import 'form_scope.dart';

/// Renders a titled card with child components.
///
/// Schema: { type: "card", title: "string", variant: "default"|"glass",
///           content: [Component[]] }
class CardWidget extends StatelessWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const CardWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final title = component['title']?.toString();
    final content = component['content'] as List<dynamic>? ?? [];
    final variant = component['variant']?.toString() ?? 'default';

    final childColumn = FormScopeWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (content.isNotEmpty) DynamicRenderer.renderChildren(content),
        ],
      ),
    );

    if (variant == 'glass') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: childColumn,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: childColumn,
      ),
    );
  }
}
