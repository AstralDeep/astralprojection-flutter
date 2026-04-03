import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/device_profile_provider.dart';
import '../../platform/tv/tv_theme.dart';

/// Renders a text input field.
///
/// Schema: { type: "input", placeholder: "string", name: "string", value: "" }
///
/// On submit: sendEvent('form_submit', { 'fields': { name: value } })
class InputWidget extends StatefulWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const InputWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.component['value']?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(InputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = widget.component['value']?.toString() ?? '';
    if (_controller.text != newValue) {
      _controller.value = _controller.value.copyWith(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitted(String value) {
    final name = widget.component['name']?.toString() ?? '';
    widget.sendEvent('form_submit', {
      'fields': {name: value},
    });
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
    final placeholder = widget.component['placeholder']?.toString();
    final name = widget.component['name']?.toString() ?? '';

    final textField = TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: placeholder,
        labelText: name.isNotEmpty ? name : null,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      onSubmitted: _onSubmitted,
    );

    return Semantics(
      textField: true,
      label: placeholder ?? name,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: _buildFocusWrapper(context, textField),
      ),
    );
  }
}
