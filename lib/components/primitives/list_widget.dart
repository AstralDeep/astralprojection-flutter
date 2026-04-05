import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders an ordered or unordered list from SDUI schema.
///
/// Schema: { type: "list", items: ["item1","item2"], ordered: false,
///   variant: "default" }
class ListWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const ListWidget({required this.component, super.key});

  @override
  Widget build(BuildContext context) {
    final items = component['items'] as List<dynamic>? ?? [];
    final ordered = component['ordered'] == true;

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++)
            _buildItem(context, items[i], i, ordered),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    dynamic item,
    int index,
    bool ordered,
  ) {
    final text = _itemToString(item);

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ordered ? 28.0 : 20.0,
            child: ordered
                ? Text(
                    '${index + 1}.',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: AstralColors.primary,
                      height: 1.5,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: AstralColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AstralColors.text.withValues(alpha: 0.9),
                fontSize: 14.0,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _itemToString(dynamic item) {
    if (item is String) return item;
    if (item is Map || item is List) return jsonEncode(item);
    if (item == null) return '';
    return item.toString();
  }
}
