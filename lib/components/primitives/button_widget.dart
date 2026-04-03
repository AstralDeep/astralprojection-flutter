import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/device_profile_provider.dart';
import '../../platform/tv/tv_theme.dart';

/// Renders a clickable button that dispatches a ui_event.
///
/// Schema: { type: "button", label: "string", action: "string",
///           payload: {}, variant: "primary"|"secondary" }
class ButtonWidget extends StatelessWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const ButtonWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

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
    final label = component['label']?.toString() ?? 'Button';
    final action = component['action']?.toString() ?? '';
    final payload =
        component['payload'] as Map<String, dynamic>? ?? const {};
    final variant = component['variant']?.toString() ?? 'primary';
    final componentId = component['id']?.toString();

    void onPressed() {
      sendEvent(action, {
        ...payload,
        if (componentId != null) 'component_id': componentId,
      });
    }

    final button = switch (variant) {
      'secondary' => OutlinedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      _ => ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
    };

    return Semantics(
      button: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: _buildFocusWrapper(context, button),
      ),
    );
  }
}
