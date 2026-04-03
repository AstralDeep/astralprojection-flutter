import 'package:flutter/material.dart';
import '../dynamic_renderer.dart';

/// Renders children in a responsive grid layout.
///
/// Schema: { type: "grid", columns: 2, gap: 20, children: [Component[]] }
class GridWidget extends StatelessWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const GridWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final columns = (component['columns'] as num?)?.toInt() ?? 2;
    final gap = (component['gap'] as num?)?.toDouble() ?? 16.0;
    final children = component['children'] as List<dynamic>? ?? [];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalGap = gap * (columns - 1);
          final childWidth = (constraints.maxWidth - totalGap) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final child in children)
                if (child is Map<String, dynamic>)
                  SizedBox(
                    width: childWidth.clamp(0, constraints.maxWidth),
                    child: DynamicRenderer(component: child),
                  ),
            ],
          );
        },
      ),
    );
  }
}
