import 'package:flutter/material.dart';
import '../dynamic_renderer.dart';

/// Renders a vertical stack of children via DynamicRenderer.
///
/// Schema: { type: "container", children: [Component[]] }
class ContainerWidget extends StatelessWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const ContainerWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final children = component['children'] as List<dynamic>? ?? [];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return DynamicRenderer.renderChildren(children);
  }
}
