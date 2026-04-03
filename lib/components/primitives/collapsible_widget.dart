import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/device_profile_provider.dart';
import '../../platform/tv/tv_theme.dart';
import '../dynamic_renderer.dart';

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

    final tile = ExpansionTile(
      title: Text(title),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _isExpanded = expanded);
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: DynamicRenderer.renderChildren(content),
        ),
      ],
    );

    return _buildFocusWrapper(context, tile);
  }
}
