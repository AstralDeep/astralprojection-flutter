import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'primitives.dart';
import '../state/web_socket_provider.dart';

// Map backend type strings to frontend widget implementations
final Map<String, Widget Function(Map<String, dynamic> primitive, {
  void Function(Map<String, dynamic>)? sendAction,
  void Function(String)? onValueChange,
  void Function()? onAction,
})> primitiveMap = {
  'StackLayout': (primitive, {sendAction, onValueChange, onAction}) => StackLayoutWidget(primitive: primitive, sendAction: sendAction),
  'TextView': (primitive, {sendAction, onValueChange, onAction}) => TextViewWidget(primitive: primitive),
  'LogView': (primitive, {sendAction, onValueChange, onAction}) => LogViewWidget(primitive: primitive),
  'InputField': (primitive, {sendAction, onValueChange, onAction}) => InputFieldWidget(primitive: primitive, onValueChange: onValueChange, onAction: onAction),
  'Button': (primitive, {sendAction, onValueChange, onAction}) => ButtonWidget(primitive: primitive, onAction: onAction),
  'ChatViewBasic': (primitive, {sendAction, onValueChange, onAction}) => ChatViewBasicWidget(primitive: primitive),
  'McpStructuredLogView': (primitive, {sendAction, onValueChange, onAction}) => McpStructuredLogViewWidget(primitive: primitive),
  'StreamingTextView': (primitive, {sendAction, onValueChange, onAction}) => StreamingTextViewWidget(primitive: primitive),
  'CodeView': (primitive, {sendAction, onValueChange, onAction}) => CodeViewWidget(primitive: primitive),
  'HtmlView': (primitive, {sendAction, onValueChange, onAction}) => HtmlViewWidget(primitive: primitive),
};

class UnknownPrimitiveWidget extends StatelessWidget {
  final String id;
  final String type;
  final String? gridArea;
  const UnknownPrimitiveWidget({required this.id, required this.type, this.gridArea, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2, style: BorderStyle.solid),
        color: Colors.red.withOpacity(0.05),
      ),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unknown Primitive Type: "$type"', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Text('ID: $id', style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

// --- Helper Functions ---
Map<String, dynamic>? findPrimitiveById(Map<String, dynamic>? node, String? targetId) {
  if (node == null || targetId == null) return null;
  if (node['id'] == targetId) return node;
  if (node['children'] is List) {
    for (final child in node['children']) {
      if (child is Map<String, dynamic>) {
        final found = findPrimitiveById(child, targetId);
        if (found != null) return found;
      }
    }
  }
  return null;
}

Map<String, dynamic>? findPrimitiveByBinding(Map<String, dynamic>? node, String? targetBinding) {
  if (node == null || targetBinding == null) return null;
  if (node['updateBinding'] == targetBinding) return node;
  if (node['children'] is List) {
    for (final child in node['children']) {
      if (child is Map<String, dynamic>) {
        final found = findPrimitiveByBinding(child, targetBinding);
        if (found != null) return found;
      }
    }
  }
  return null;
}
// --- End Helper Functions ---

class DynamicRenderer extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(Map<String, dynamic> message)? sendAction;
  const DynamicRenderer({Key? key, required this.primitive, this.sendAction}) : super(key: key);
  @override
  State<DynamicRenderer> createState() => _DynamicRendererState();
}

class _DynamicRendererState extends State<DynamicRenderer> {
  Map<String, dynamic> _contentOverrides = {};
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.primitive['type'] == 'InputField') {
      _controller = TextEditingController(text: widget.primitive['content'] ?? '');
    }
  }

  @override
  void didUpdateWidget(DynamicRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.primitive['type'] == 'InputField') {
      final newText = widget.primitive['content'] ?? '';
      if (_controller != null && _controller!.text != newText) {
        _controller!.text = newText;
      }
    }
  }

  void _handleValueChange(String value) {
    setState(() {
      _contentOverrides['content'] = value;
    });
  }

  void _handleAction() {
    final primitive = widget.primitive;
    final actionId = primitive['actionId'] ?? primitive['id'];
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);

    String value = primitive['content'] ?? '';
    if (_controller != null) {
      value = _controller!.text;
    } else if (_contentOverrides.containsKey('content')) {
      value = _contentOverrides['content'];
    }

    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final valueSourceElementIds = config['valueSourceElementIds'] as List<dynamic>?;
    Map<String, dynamic> valuesFromSources = {};
    if (valueSourceElementIds != null && valueSourceElementIds.isNotEmpty) {
      for (final id in valueSourceElementIds) {
        String sourceValue = '';
        if (id == primitive['id'] && _controller != null) {
          sourceValue = _controller!.text;
        } else {
          final root = wsProvider.uiState != null ? wsProvider.uiState!['rootElement'] : null;
          if (root != null) {
            final found = wsProvider.findPrimitiveById(root, id);
            if (found != null && found['content'] != null) {
              sourceValue = found['content'].toString();
            }
          }
        }
        valuesFromSources[id.toString()] = sourceValue;
      }
    }

    String argumentKey = 'value';
    if (config['argumentKey'] is String) {
      argumentKey = config['argumentKey'];
    } else if (primitive['argumentKey'] is String) {
      argumentKey = primitive['argumentKey'];
    }
    if ((actionId == 'chatbot_query' || actionId == 'process_user_query' || 
        actionId.toString().contains('query')) && argumentKey != 'query') {
      argumentKey = 'query';
    }

    String valueToSend = value;
    if (valueSourceElementIds != null && valueSourceElementIds.isNotEmpty) {
      for (final id in valueSourceElementIds) {
        final idStr = id.toString();
        if (idStr.contains('input') || idStr.contains('chat') || idStr.contains('query')) {
          if (valuesFromSources.containsKey(idStr) && valuesFromSources[idStr].toString().isNotEmpty) {
            valueToSend = valuesFromSources[idStr].toString();
            break;
          }
        }
      }
    }

    final frontendActions = config['frontendActions'] as List<dynamic>?;
    Map<String, dynamic> valuesForBackend = valuesFromSources.isNotEmpty ? valuesFromSources : {primitive['id']: valueToSend};
    if (frontendActions != null && frontendActions.isNotEmpty) {
      wsProvider.performFrontendActions(frontendActions, valuesForBackend);
    }

    if (widget.sendAction != null) {
      widget.sendAction!({
        'type': 'ui_action',
        'payload': {
          'actionId': actionId,
          'sourceElementId': primitive['id'],
          'arguments': {argumentKey: 'hi'}
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
      if (type == 'InputField') {
        return InputFieldWidget(
          primitive: primitiveWithOverrides,
          onValueChange: _handleValueChange,
          onAction: _handleAction,
          key: ValueKey(id),
        );
      }
      return widgetBuilder(
        primitiveWithOverrides,
        sendAction: widget.sendAction,
        onValueChange: _handleValueChange,
        onAction: _handleAction,
      );
    }
    return UnknownPrimitiveWidget(id: id.toString(), type: type.toString());
  }
}
