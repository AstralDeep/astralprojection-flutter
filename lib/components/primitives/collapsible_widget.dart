import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/device_profile_provider.dart';
import '../../platform/tv/tv_theme.dart';
import '../dynamic_renderer.dart';
import '../theme/app_theme.dart';

/// Renders a collapsible section using ExpansionTile.
///
/// Schema: { type: "collapsible", title: "Section Title", default_open: false, content: [Component[]] }
class CollapsibleWidget extends StatefulWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const CollapsibleWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  State<CollapsibleWidget> createState() => _CollapsibleWidgetState();
}

class _CollapsibleWidgetState extends State<CollapsibleWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.component['default_open'] as bool? ?? false;
  }

  /// Wraps [child] with a Focus widget that shows a highlight border on TV.
  Widget _buildFocusWrapper(BuildContext context, Widget child) {
    final dp = Provider.of<DeviceProfileProvider>(context, listen: false);
    if (dp.deviceType != 'tv') return child;

    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            decoration: hasFocus
                ? BoxDecoration(
                    border: Border.all(
                      color: TvTheme.focusBorderColor,
                      width: TvTheme.focusBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  )
                : null,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.component['title']?.toString() ?? 'Untitled';
    final content = widget.component['content'] as List<dynamic>? ?? [];

    final tile = Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AstralColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
          ),
          iconColor: AstralColors.primary,
          collapsedIconColor: AstralColors.text.withValues(alpha: 0.5),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: DynamicRenderer.renderChildren(content),
            ),
          ],
        ),
      ),
    );

    return _buildFocusWrapper(context, tile);
  }
}
