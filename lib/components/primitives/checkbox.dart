import 'package:flutter/material.dart';

class CheckboxWidget extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(String?)? onValueChange;
  final void Function()? onAction;

  const CheckboxWidget({
    required this.primitive,
    this.onValueChange,
    this.onAction,
    super.key,
  });

  @override
  State<CheckboxWidget> createState() => _CheckboxWidgetState();
}

class _CheckboxWidgetState extends State<CheckboxWidget> {
  // Used when the widget is "uncontrolled"
  late bool _internalChecked;

  @override
  void initState() {
    super.initState();
    _internalChecked = _getInitialCheckedState();
  }

  // This logic determines the initial state by checking props in the correct order.
  bool _getInitialCheckedState() {
    final content = widget.primitive['content'];
    if (content is bool) {
      return content;
    }
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    return config['initialChecked'] == true;
  }

  @override
  void didUpdateWidget(CheckboxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the primitive from the parent changes, re-evaluate the initial checked state.
    // This allows the parent to change the checkbox state via props.
    if (widget.primitive['content'] != oldWidget.primitive['content'] ||
        widget.primitive['config']?['initialChecked'] != oldWidget.primitive['config']?['initialChecked']) {
      setState(() {
        _internalChecked = _getInitialCheckedState();
      });
    }
  }

  void _handleChange(bool? newValue) {
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    final bool isDisabled = config['disabled'] == true;
    final bool isControlled = widget.primitive['content'] is bool;

    if (newValue == null || isDisabled) {
      return;
    }

    // If uncontrolled, update the internal state to re-render the UI
    if (!isControlled) {
      setState(() {
        _internalChecked = newValue;
      });
    }

    // Always notify the parent/store of the new value.
    // Your renderer expects a String?, so we convert the boolean.
    widget.onValueChange?.call(newValue.toString());

    // Trigger the action if provided.
    widget.onAction?.call();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    final content = widget.primitive['content'];

    // --- Determine state and properties ---
    final String label = config['label']?.toString() ?? '';
    final bool isDisabled = config['disabled'] == true;
    final bool isControlled = content is bool;
    final bool currentChecked = isControlled ? content : _internalChecked;
    
    // To make the entire row tappable, we wrap it in InkWell
    return InkWell(
      onTap: isDisabled ? null : () => _handleChange(!currentChecked),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: currentChecked,
              // The `onChanged` of the checkbox itself also triggers the handler
              onChanged: isDisabled ? null : _handleChange,
              // Apply disabled appearance
              activeColor: isDisabled ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
            if (label.isNotEmpty)
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDisabled ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}