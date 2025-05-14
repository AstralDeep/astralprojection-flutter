import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final title = config['title']?.toString() ?? primitive['id']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              const Text('Chat', style: TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
          const Divider(height: 24),
          if (content.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Conversation started.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])),
            ),
          for (final msg in content)
            if (msg is Map<String, dynamic>)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                child: Align(
                  alignment: msg['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: msg['role'] == 'user' ? Colors.blue[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: msg['role'] == 'user' ? Colors.blue[900] : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
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
  void didUpdateWidget(InputFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if primitive content changes externally
    final newText = widget.primitive['content'] ?? '';
    if (_controller.text != newText) {
      _controller.text = newText;
    }
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
        onSubmitted: (val) {
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
    final content = primitive['content'];
    List<dynamic> entries = [];
    if (content is List) {
      entries = content;
    } else if (content != null) {
      entries = [content];
    }
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: entries.isEmpty
          ? Text('No log entries.', style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      entry is Map && entry.containsKey('message')
                          ? entry['message'].toString()
                          : entry.toString(),
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
              ],
            ),
    );
  }
}

class MarkdownViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const MarkdownViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] ?? '';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MarkdownBody(data: content.toString()),
    );
  }
}

class StreamingTextViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const StreamingTextViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] ?? '';
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SelectableText(content.toString()),
    );
  }
}

class CodeViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const CodeViewWidget({required this.primitive, Key? key}) : super(key: key);
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
      child: SelectableText(
        content.toString(),
        style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
      ),
    );
  }
}

class HtmlViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const HtmlViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'];
    // Basic rendering: show as string, table, or error. Expand as needed.
    if (content is Map && content.containsKey('viz_type')) {
      final vizType = content['viz_type'];
      final vizContent = content['content'];
      if (vizType == 'table' && vizContent is Map) {
        final columns = vizContent['columns'] as List<dynamic>? ?? [];
        final rows = vizContent['rows'] as List<dynamic>? ?? [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns.map((c) => DataColumn(label: Text(c.toString()))).toList(),
            rows: rows.map((row) {
              final cells = row as List<dynamic>? ?? [];
              return DataRow(
                cells: cells.map((cell) => DataCell(Text(cell?.toString() ?? ''))).toList(),
              );
            }).toList(),
          ),
        );
      } else if (vizType == 'message' || vizType == 'scalar') {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(vizContent?.toString() ?? ''),
        );
      } else if (vizType == 'error') {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(vizContent?.toString() ?? '', style: const TextStyle(color: Colors.red)),
        );
      }
    }
    // Fallback: render as string
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(content?.toString() ?? ''),
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
  'StreamingTextView': (primitive, {sendAction, onValueChange, onAction}) => StreamingTextViewWidget(primitive: primitive),
  'CodeView': (primitive, {sendAction, onValueChange, onAction}) => CodeViewWidget(primitive: primitive),
  'HtmlView': (primitive, {sendAction, onValueChange, onAction}) => HtmlViewWidget(primitive: primitive),
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
    if (config['argumentKey'] is String) {
      argumentKey = config['argumentKey'];
    } else if (primitive['argumentKey'] is String) {
      argumentKey = primitive['argumentKey'];
    } else if (valueSourceElementIds != null && valueSourceElementIds.isNotEmpty) {
      argumentKey = valueSourceElementIds.first.toString();
    }
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
