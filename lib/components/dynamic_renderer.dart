import 'package:flutter/material.dart';

class StackLayoutWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function(Map<String, dynamic> message)? sendAction;
  const StackLayoutWidget({required this.primitive, this.sendAction, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final children = primitive['children'] as List<dynamic>? ?? [];
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children)
            if (child is Map<String, dynamic>)
              DynamicRenderer(primitive: child, sendAction: sendAction),
        ],
      ),
    );
  }
}

class TextViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const TextViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] ?? '';
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final fontSize = (config['fontSize'] is num) ? (config['fontSize'] as num).toDouble() : 16.0;
    final fontWeight = config['fontWeight'] == 'bold' ? FontWeight.bold : FontWeight.normal;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        content.toString(),
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
      ),
    );
  }
}

class ChatViewBasicWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const ChatViewBasicWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        for (final msg in content)
          if (msg is Map<String, dynamic>)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Align(
                alignment: msg['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: msg['role'] == 'user' ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Text(msg['text'] ?? ''),
                ),
              ),
            ),
      ],
    );
  }
}

class InputFieldWidget extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(String)? onValueChange;
  const InputFieldWidget({required this.primitive, this.onValueChange, Key? key}) : super(key: key);
  @override
  State<InputFieldWidget> createState() => _InputFieldWidgetState();
}
class _InputFieldWidgetState extends State<InputFieldWidget> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.primitive['content'] ?? '');
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.primitive['label'] ?? 'Input',
          border: const OutlineInputBorder(),
        ),
        onChanged: (val) {
          if (widget.onValueChange != null) widget.onValueChange!(val);
        },
      ),
    );
  }
}

class ButtonWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function()? onAction;
  const ButtonWidget({required this.primitive, this.onAction, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: onAction,
        child: Text(primitive['label'] ?? 'Button'),
      ),
    );
  }
}

class LogViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const LogViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] ?? '';
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(content.toString(), style: const TextStyle(color: Colors.white)),
    );
  }
}

class MarkdownViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const MarkdownViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] ?? '';
    // For simplicity, use a basic Text widget. For full markdown, use flutter_markdown package.
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(content.toString()),
    );
  }
}

final Map<String, Widget Function(Map<String, dynamic> primitive, {void Function(Map<String, dynamic>)? sendAction, void Function(String)? onValueChange, void Function()? onAction})> primitiveMap = {
  'StackLayout': (primitive, {sendAction, onValueChange, onAction}) => StackLayoutWidget(primitive: primitive, sendAction: sendAction),
  'TextView': (primitive, {sendAction, onValueChange, onAction}) => TextViewWidget(primitive: primitive),
  'ChatViewBasic': (primitive, {sendAction, onValueChange, onAction}) => ChatViewBasicWidget(primitive: primitive),
  'InputField': (primitive, {sendAction, onValueChange, onAction}) => InputFieldWidget(primitive: primitive, onValueChange: onValueChange),
  'Button': (primitive, {sendAction, onValueChange, onAction}) => ButtonWidget(primitive: primitive, onAction: onAction),
  'LogView': (primitive, {sendAction, onValueChange, onAction}) => LogViewWidget(primitive: primitive),
  'MarkdownView': (primitive, {sendAction, onValueChange, onAction}) => MarkdownViewWidget(primitive: primitive),
};

class DynamicRenderer extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(Map<String, dynamic> message)? sendAction;
  const DynamicRenderer({Key? key, required this.primitive, this.sendAction}) : super(key: key);
  @override
  State<DynamicRenderer> createState() => _DynamicRendererState();
}

class _DynamicRendererState extends State<DynamicRenderer> {
  Map<String, dynamic> _contentOverrides = {};

  void _handleValueChange(String value) {
    setState(() {
      _contentOverrides['content'] = value;
    });
  }

  void _handleAction() {
    final primitive = widget.primitive;
    final actionId = primitive['actionId'] ?? primitive['id'];
    final value = _contentOverrides['content'] ?? primitive['content'] ?? '';
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final valueSourceElementIds = config['valueSourceElementIds'] as List<dynamic>?;
    String argumentKey = 'value';
    // Prefer explicit argumentKey from config or primitive
    if (config['argumentKey'] is String) {
      argumentKey = config['argumentKey'];
    } else if (primitive['argumentKey'] is String) {
      argumentKey = primitive['argumentKey'];
    } else if (valueSourceElementIds != null && valueSourceElementIds.isNotEmpty) {
      argumentKey = valueSourceElementIds.first.toString();
    }
    // Fallback for common backend actions (e.g., chatbot_query expects 'query')
    if ((actionId == 'chatbot_query' || actionId == 'process_user_query' || actionId.toString().contains('query')) && argumentKey != 'query') {
      argumentKey = 'query';
    }
    if (widget.sendAction != null) {
      widget.sendAction!({
        'type': 'ui_action',
        'payload': {
          'actionId': actionId,
          'sourceElementId': primitive['id'],
          'arguments': {argumentKey: value}
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.primitive['type'] ?? 'Unknown';
    final id = widget.primitive['id'] ?? '';
    final widgetBuilder = primitiveMap[type];
    final primitiveWithOverrides = Map<String, dynamic>.from(widget.primitive)..addAll(_contentOverrides);
    if (widgetBuilder != null) {
      return widgetBuilder(
        primitiveWithOverrides,
        sendAction: widget.sendAction,
        onValueChange: _handleValueChange,
        onAction: _handleAction,
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Unknown Primitive', style: TextStyle(fontSize: 24, color: Colors.red)),
          Text('Type: $type'),
          Text('ID: $id'),
        ],
      ),
    );
  }
}
