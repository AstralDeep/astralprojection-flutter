import 'package:flutter/material.dart';
import 'dynamic_renderer.dart';

// --- StackLayout ---
class StackLayoutWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function(Map<String, dynamic>)? sendAction;
  const StackLayoutWidget({required this.primitive, this.sendAction, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final children = primitive['children'] as List<dynamic>? ?? [];
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final direction = (config['direction'] ?? 'vertical').toString();
    final gap = double.tryParse((config['gap'] ?? '0').toString().replaceAll('px', '')) ?? 0.0;
    final padding = double.tryParse((config['padding'] ?? '0').toString().replaceAll('px', '')) ?? 0.0;
    final alignItems = config['align_items'] ?? config['alignItems'] ?? 'stretch';
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch;
    if (alignItems == 'flex-end' || alignItems == 'end') crossAxisAlignment = CrossAxisAlignment.end;
    else if (alignItems == 'center') crossAxisAlignment = CrossAxisAlignment.center;
    else if (alignItems == 'flex-start' || alignItems == 'start') crossAxisAlignment = CrossAxisAlignment.start;
    return Container(
      padding: EdgeInsets.all(padding),
      child: direction == 'horizontal'
          ? Row(
              crossAxisAlignment: crossAxisAlignment,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  if (children[i] is Map<String, dynamic>)
                    Expanded(
                      child: DynamicRenderer(
                        key: ValueKey(children[i]['id'] ?? i),
                        primitive: children[i] as Map<String, dynamic>,
                        sendAction: sendAction,
                      ),
                    ),
                ]
              ],
            )
          : Column(
              crossAxisAlignment: crossAxisAlignment,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  if (children[i] is Map<String, dynamic>)
                    DynamicRenderer(
                      key: ValueKey(children[i]['id'] ?? i),
                      primitive: children[i] as Map<String, dynamic>,
                      sendAction: sendAction,
                    ),
                ]
              ],
            ),
    );
  }
}

// --- TextView ---
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

// --- LogView ---
class LogViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const LogViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'];
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final style = config['style'] as Map<String, dynamic>? ?? {};
    final height = style['height'] != null ? double.tryParse(style['height'].toString().replaceAll('px', '')) : null;
    List<dynamic> entries = [];
    if (content is List) {
      entries = content;
    } else if (content != null) {
      entries = [content];
    }
    final logList = entries.isEmpty
        ? Text('No log entries.', style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic))
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, idx) {
              final entry = entries[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  entry.toString(),
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                ),
              );
            },
          );
    if (height != null) {
      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(12.0),
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: logList,
      );
    } else {
      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: logList,
      );
    }
  }
}

// --- InputField ---
class InputFieldWidget extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(String)? onValueChange;
  final void Function()? onAction;
  const InputFieldWidget({required this.primitive, this.onValueChange, this.onAction, Key? key}) : super(key: key);
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
    final newText = widget.primitive['content'] ?? '';
    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }
  @override
  Widget build(BuildContext context) {
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    final multiline = config['multiline'] == true;
    final placeholder = config['placeholder']?.toString();
    final enterKeyAction = config['enterKeyAction'] as Map<String, dynamic>?;
    final textField = TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.primitive['label'] ?? 'Input',
        hintText: placeholder,
        border: const OutlineInputBorder(),
      ),
      minLines: multiline ? (config['rows'] ?? 3) : 1,
      maxLines: multiline ? null : 1,
      onChanged: (val) {
        if (widget.onValueChange != null) widget.onValueChange!(val);
      },
      onSubmitted: (val) {
        if (widget.onValueChange != null) widget.onValueChange!(val);
        if (!multiline && enterKeyAction != null && enterKeyAction['isEnabled'] == true && widget.onAction != null) {
          widget.onAction!();
        } else if (!multiline && widget.onAction != null) {
          widget.onAction!();
        }
      },
    );
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: textField,
    );
  }
}

// --- Button ---
class ButtonWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function()? onAction;
  const ButtonWidget({required this.primitive, this.onAction, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final label = config['label'] ?? primitive['label'] ?? 'Button';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: onAction,
        child: Text(label),
      ),
    );
  }
}

// --- ChatViewBasic ---
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
          content.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Conversation started.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: content.length,
                  itemBuilder: (context, idx) {
                    final msg = content[idx];
                    if (msg is Map<String, dynamic>) {
                      return Padding(
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
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ],
      ),
    );
  }
}

// --- McpStructuredLogView ---
class McpStructuredLogViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const McpStructuredLogViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] as List<dynamic>? ?? [];
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final height = config['height'] != null ? double.tryParse(config['height'].toString().replaceAll('px', '')) : null;
    final logList = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: content.length,
      itemBuilder: (context, idx) {
        final entry = content[idx];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(entry.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        );
      },
    );
    if (height != null) {
      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(12.0),
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: logList,
      );
    } else {
      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: logList,
      );
    }
  }
}

// --- StreamingTextView ---
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

// --- CodeView ---
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

// --- HtmlView ---
class HtmlViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const HtmlViewWidget({required this.primitive, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final content = primitive['content'];
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
          child: Text(
            vizContent?.toString() ?? '',
          ),
        );
      } else if (vizType == 'error') {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            vizContent?.toString() ?? '',
            style: const TextStyle(color: Colors.red),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        content?.toString() ?? '',
      ),
    );
  }
}
