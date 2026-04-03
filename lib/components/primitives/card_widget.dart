import 'package:flutter/material.dart';
import '../dynamic_renderer.dart';

/// Renders a titled card with child components.
///
/// Schema: { type: "card", title: "string", variant: "default",
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            if (content.isNotEmpty)
              DynamicRenderer.renderChildren(content),
          ],
        ),
      ),
    );
  }
}
