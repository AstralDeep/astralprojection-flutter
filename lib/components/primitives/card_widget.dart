import 'dart:ui';
import 'package:flutter/material.dart';
import '../dynamic_renderer.dart';
import '../theme/app_theme.dart';
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AstralColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
              ),
            ),
          if (content.isNotEmpty) DynamicRenderer.renderChildren(content),
        ],
      ),
    );

    if (variant == 'glass') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AstralColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AstralColors.primary.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: AstralColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: childColumn,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AstralColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AstralColors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AstralColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: childColumn,
    );
  }
}
