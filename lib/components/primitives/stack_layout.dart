import 'package:flutter/material.dart';
import '../dynamic_renderer.dart';

// --- StackLayout ---
class StackLayoutWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function(Map<String, dynamic>)? sendAction; // Assuming this signature for sendAction
  const StackLayoutWidget({required this.primitive, this.sendAction, super.key});

  @override
  Widget build(BuildContext context) {
    final children = primitive['children'] as List<dynamic>? ?? [];
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final direction = (config['direction'] ?? 'vertical').toString();
    final gap = double.tryParse((config['gap'] ?? '0').toString().replaceAll('px', '')) ?? 0.0;
    final paddingValue = double.tryParse((config['padding'] ?? '0').toString().replaceAll('px', '')) ?? 0.0;
    final alignItems = config['align_items'] ?? config['alignItems'] ?? 'stretch';

    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch;
    if (alignItems == 'flex-end' || alignItems == 'end') {
      crossAxisAlignment = CrossAxisAlignment.end;
    } else if (alignItems == 'center') {
      crossAxisAlignment = CrossAxisAlignment.center;
    } else if (alignItems == 'flex-start' || alignItems == 'start') {
      crossAxisAlignment = CrossAxisAlignment.start;
    }

    return Container(
      padding: EdgeInsets.all(paddingValue),
      child: direction == 'horizontal'
          ? Row(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.max,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  if (children[i] is Map<String, dynamic>)
                    Expanded(
                      child: DynamicRenderer(
                        key: ValueKey(children[i]['id']?.toString() ?? 'child_$i'),
                        component: children[i] as Map<String, dynamic>,
                      ),
                    ),
                ]
              ],
            )
          : Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.max,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  if (children[i] is Map<String, dynamic>)
                    DynamicRenderer(
                      key: ValueKey(children[i]['id']?.toString() ?? 'child_$i'),
                      component: children[i] as Map<String, dynamic>,
                    ),
                ]
              ],
            ),
    );
  }
}