import 'package:flutter/material.dart';
import 'dynamic_renderer.dart'; // Assuming 'dynamic_renderer.dart' is in the same directory or a correct path

// --- StackLayout ---
class StackLayoutWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function(Map<String, dynamic>)? sendAction; // Assuming this signature for sendAction
  const StackLayoutWidget({required this.primitive, this.sendAction, super.key});

  @override
  Widget build(BuildContext context) {
    final children = primitive['children'] as List<dynamic>? ?? [];
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final direction = (config['direction'] ?? 'vertical').toString();
    final gap = double.tryParse((config['gap'] ?? '0').toString().replaceAll('px', '')) ?? 0.0;
    final paddingValue = double.tryParse((config['padding'] ?? '0').toString().replaceAll('px', '')) ?? 0.0;
    final alignItems = config['align_items'] ?? config['alignItems'] ?? 'stretch';

    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch;
    if (alignItems == 'flex-end' || alignItems == 'end') {
      crossAxisAlignment = CrossAxisAlignment.end;
    } else if (alignItems == 'center') {
      crossAxisAlignment = CrossAxisAlignment.center;
    } else if (alignItems == 'flex-start' || alignItems == 'start') {
      crossAxisAlignment = CrossAxisAlignment.start;
    }

    return Container(
      padding: EdgeInsets.all(paddingValue),
      child: direction == 'horizontal'
          ? Row(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.max,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  if (children[i] is Map<String, dynamic>)
                    Expanded(
                      child: DynamicRenderer(
                        key: ValueKey(children[i]['id']?.toString() ?? 'child_$i'),
                        primitive: children[i] as Map<String, dynamic>,
                        sendAction: sendAction,
                      ),
                    ),
                ]
              ],
            )
          : Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.max,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  if (children[i] is Map<String, dynamic>)
                    DynamicRenderer(
                      key: ValueKey(children[i]['id']?.toString() ?? 'child_$i'),
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
  const TextViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] ?? primitive['config']?['initialText'] ?? '';
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final fontSize = (config['fontSize'] is num) ? (config['fontSize'] as num).toDouble() : 16.0;
    final fontWeightStr = config['fontWeight']?.toString() ?? 'normal';
    final variant = config['variant']?.toString();

    TextStyle style = TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeightStr == 'bold' ? FontWeight.bold : FontWeight.normal
    );

    if (variant == 'headline') {
        style = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: style.fontWeight) ?? style.copyWith(fontSize: 24);
    } else if (variant == 'titleSmall') {
        style = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: style.fontWeight) ?? style.copyWith(fontSize: 18);
    } else if (variant == 'caption') {
        style = Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: style.fontWeight, color: Colors.grey[600]) ?? style.copyWith(fontSize: 12, color: Colors.grey[600]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        content.toString(),
        style: style,
      ),
    );
  }
}

// --- LogView ---
class LogViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const LogViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'];
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final styleConfig = config['style'] as Map<String, dynamic>? ?? {};
    
    final height = styleConfig['height'] != null
        ? double.tryParse(styleConfig['height'].toString().replaceAll('px', ''))
        : null;
    final title = config['title']?.toString() ?? "Logs";

    double marginTopValue = 8.0; 
    if (styleConfig['marginTop'] != null) {
      // Ensure robust parsing for marginTopValue
      String marginTopString = styleConfig['marginTop'].toString();
      if (marginTopString.endsWith('px')) {
        marginTopString = marginTopString.substring(0, marginTopString.length - 2);
      }
      marginTopValue = double.tryParse(marginTopString) ?? 8.0;
    }

    List<dynamic> entries = [];
    if (content is List) {
      entries = content;
    } else if (content != null) {
      entries = [content];
    }

    Widget logListContent;
    if (entries.isEmpty) {
      logListContent = Center(
          child: Text('No log entries.',
              style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)));
    } else {
      logListContent = ListView.builder(
        shrinkWrap: height == null,
        physics: height == null ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, idx) {
          final entry = entries[idx];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              entry.toString(),
              style: const TextStyle(
                  color: Colors.black87, fontFamily: 'monospace', fontSize: 13),
            ),
          );
        },
      );
    }

    Widget logContainer = Container(
      margin: EdgeInsets.symmetric(vertical: marginTopValue), // Use the parsed marginTopValue
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(height: 16),
          Expanded( // <<<<<<<<<<<<<<<< CORRECTED HERE
            child: logListContent,
          ),
        ],
      )
    );
    
     if (height != null) {
       return SizedBox(height: height, child: logContainer); // Constrain the whole widget if height is specified
     } else {
       return logContainer;
     }
  }
}


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

// --- Button ---
class ButtonWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  final void Function()? onAction;
  const ButtonWidget({required this.primitive, this.onAction, super.key});

  @override
  Widget build(BuildContext context) {
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final label = config['label']?.toString() ?? primitive['label']?.toString() ?? 'Button';

    return ElevatedButton(
      onPressed: onAction,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}

// --- ChatViewBasic ---
class ChatViewBasicWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const ChatViewBasicWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] as List<dynamic>? ?? [];
    final title = primitive['config']?['title']?.toString() ?? 'Chat';
    return Container(
      height: 300, 
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          Expanded(
            child: content.isEmpty
                ? const Center(child: Text("No messages."))
                : ListView.builder(
                    itemCount: content.length,
                    itemBuilder: (ctx, idx) {
                      final item = content[idx] as Map<String, dynamic>? ?? {};
                      return ListTile(
                        title: Text(item['text']?.toString() ?? ''),
                        subtitle: Text(item['role']?.toString() ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- McpStructuredLogView ---
class McpStructuredLogViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const McpStructuredLogViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] as List<dynamic>? ?? [];
    return Container(
      height: 200, 
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey)),
      child: content.isEmpty
          ? const Text("No structured logs.")
          : ListView.builder(
              itemCount: content.length,
              itemBuilder: (context, index) => Text(content[index].toString()),
            ),
    );
  }
}

// --- StreamingTextView ---
class StreamingTextViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const StreamingTextViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectableText(content),
    );
  }
}

// --- CodeView ---
class CodeViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const CodeViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content']?.toString() ?? '';
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: SelectableText(
        content,
        style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
      ),
    );
  }
}

// --- HtmlView ---
class HtmlViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const HtmlViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'];
    String textContent = "HTML content (rendering not fully implemented)";
    if (content is Map && content.containsKey('viz_type')) {
       final vizType = content['viz_type'];
       final vizContent = content['content'];
      if (vizType == 'table' && vizContent is Map) {
        final columnsData = vizContent['columns'] as List<dynamic>? ?? [];
        final rowsData = vizContent['rows'] as List<dynamic>? ?? [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columnsData.map((c) => DataColumn(label: Text(c.toString()))).toList(),
            rows: rowsData.map((row) {
              final cells = row as List<dynamic>? ?? [];
              return DataRow(cells: cells.map((cell) => DataCell(Text(cell?.toString() ?? ''))).toList());
            }).toList(),
          ),
        );
      }
      textContent = vizContent?.toString() ?? 'Unsupported HTML viz type';
    } else {
        textContent = content?.toString() ?? 'Invalid HTML content';
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(textContent),
    );
  }
}