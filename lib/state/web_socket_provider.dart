import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connected = false;
  String? _lastMessage;
  String? _error;
  Map<String, dynamic>? _uiState;

  bool get connected => _connected;
  String? get lastMessage => _lastMessage;
  String? get error => _error;
  Map<String, dynamic>? get uiState => _uiState;

  void _updatePrimitiveContent(Map<String, dynamic> update) {
    if (_uiState == null || _uiState!['rootElement'] == null) return;
    final targetId = update['targetId'];
    final targetBinding = update['targetBinding'];
    final content = update['content'];
    final updateType = update['updateType'] ?? 'replace';
    void updateContent(Map<String, dynamic> node) {
      if ((targetId != null && node['id'] == targetId) ||
          (targetBinding != null && node['updateBinding'] == targetBinding)) {
        if (updateType == 'append') {
          if (node['content'] is String) {
            // For streaming text, append as string
            node['content'] = (node['content'] ?? '').toString() + (content ?? '').toString();
          } else if (node['content'] is List) {
            // For chat/log views, append to list
            if (content is List) {
              node['content'].addAll(content);
            } else if (content != null) {
              node['content'].add(content);
            }
          } else if (node['content'] == null) {
            // If content is null, initialize as list or string
            if (content is List) {
              node['content'] = List.from(content);
            } else if (content is String) {
              node['content'] = content;
            } else {
              node['content'] = [content];
            }
          } else {
            // Convert non-list, non-string content to list and append
            node['content'] = [node['content'], content];
          }
        } else {
          node['content'] = content;
        }
      } else if (node['children'] is List) {
        for (final child in node['children']) {
          if (child is Map<String, dynamic>) updateContent(child);
        }
      }
    }
    updateContent(_uiState!['rootElement']);
    notifyListeners();
  }

  // --- Helper: Find primitive by ID ---
  Map<String, dynamic>? findPrimitiveById(Map<String, dynamic> node, String targetId) {
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

  // --- Helper: Find primitive by updateBinding ---
  Map<String, dynamic>? findPrimitiveByBinding(Map<String, dynamic> node, String targetBinding) {
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

  // --- Helper: Perform frontend actions (echoToView, clearElement) ---
  void performFrontendActions(List<dynamic> frontendActions, Map<String, dynamic> valuesForBackend) {
    if (_uiState == null || _uiState!['rootElement'] == null) return;
    final root = _uiState!['rootElement'];
    for (final action in frontendActions) {
      if (action is! Map<String, dynamic>) continue;
      switch (action['type']) {
        case 'clearElement':
          final targetId = action['targetElementId'];
          if (targetId != null) {
            final target = findPrimitiveById(root, targetId);
            if (target != null) {
              target['content'] = '';
            }
          }
          break;
        case 'echoToView':
          final sourceId = action['sourceElementId'];
          final targetBinding = action['targetBinding'];
          final role = action['role'] ?? 'user';
          if (sourceId != null && targetBinding != null) {
            final textToEcho = valuesForBackend[sourceId]?.toString() ?? '';
            if (textToEcho.trim().isEmpty) continue;
            final targetView = findPrimitiveByBinding(root, targetBinding);
            if (targetView != null) {
              final msg = {'role': role, 'text': textToEcho, 'uniqueId': DateTime.now().millisecondsSinceEpoch.toString()};
              if (targetView['content'] is List) {
                targetView['content'].add(msg);
              } else if (targetView['content'] == null) {
                targetView['content'] = [msg];
              } else {
                targetView['content'] = [targetView['content'], msg];
              }
            }
          }
          break;
        default:
          // Unknown frontend action
          break;
      }
    }
    notifyListeners();
  }

  void connect({required String url, String? jwt}) {
    disconnect();
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(url),
      );
      _connected = true;
      _error = null;
      // Send register_capabilities message immediately after connecting
      final registerMsg = jsonEncode({
        'type': 'register_capabilities',
        'payload': {
          'supported_primitives': [
            'StackLayout',
            'ChatViewBasic',
            'InputField',
            'Button',
            'TextView',
            'LogView',
            'McpStructuredLogView',
            'StreamingTextView',
            'CodeView',
            'HtmlView',
          ]
        }
      });
      _channel!.sink.add(registerMsg);
      // Only send JWT for authentication if provided (legacy, not used with query param)
      if (jwt != null && jwt.isNotEmpty) {
        _channel!.sink.add(jsonEncode({'type': 'auth', 'token': jwt}));
      }
      _subscription = _channel!.stream.listen(
        (message) {
          _lastMessage = message;
          // Parse and handle initial_ui_state
          try {
            final decoded = jsonDecode(message);
            if (decoded is Map<String, dynamic>) {
              if (decoded['type'] == 'initial_ui_state') {
                _uiState = decoded['payload'];
              } else if (decoded['type'] == 'primitive_content_update') {
                _updatePrimitiveContent(decoded['payload']);
              }
            }
          } catch (_) {}
          notifyListeners();
        },
        onError: (err) {
          _error = err.toString();
          _connected = false;
          notifyListeners();
        },
        onDone: () {
          _connected = false;
          notifyListeners();
        },
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _connected = false;
      notifyListeners();
    }
  }

  void send(dynamic data) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
