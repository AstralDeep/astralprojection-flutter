import 'package:flutter/material.dart';

// --- InputField ---
class InputFieldWidget extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(String)? onValueChange; 
  final void Function()? onAction; 
  const InputFieldWidget(
      {required this.primitive, this.onValueChange, this.onAction, super.key});

  @override
  State<InputFieldWidget> createState() => _InputFieldWidgetState();
}

class _InputFieldWidgetState extends State<InputFieldWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.primitive['content']?.toString() ?? '');
  }

  @override
  void didUpdateWidget(InputFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = widget.primitive['content']?.toString() ?? '';
    if (_controller.text != newText) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted && _controller.text != newText) {
            _controller.value = _controller.value.copyWith(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length), 
            );
         }
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    final label = widget.primitive['label']?.toString() ?? config['label']?.toString() ?? 'Input';
    final multiline = config['multiline'] == true;
    final placeholder = config['placeholder']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        minLines: multiline ? (config['rows'] as int? ?? 3) : 1,
        maxLines: multiline ? (config['rows'] as int? ?? 3) : 1, 
        onChanged: widget.onValueChange,
        onSubmitted: (value) {
          if (widget.onAction != null) {
            widget.onAction!();
          }
        },
      ),
    );
  }
   @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}