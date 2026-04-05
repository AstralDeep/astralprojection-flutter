import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../config.dart';

/// WebSocket provider implementing the AstralBody protocol:
/// register_ui, ui_render, ui_update, ui_append, ui_event.
///
/// Also handles SDUI tree disk persistence (T014) — saves last rendered
/// component tree to SharedPreferences so the cached UI can be shown
/// while reconnecting on app restart.
class WebSocketProvider extends ChangeNotifier {
  final _logger = Logger();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connected = false;
  String? _sessionId;
  String? _error;

  /// The current SDUI component tree (list of top-level components).
  List<Map<String, dynamic>> _components = [];

  /// Whether we have received at least one ui_render from the backend.
  bool _hasReceivedRender = false;

  /// Chat messages appended via ui_append.
  final List<Map<String, dynamic>> _chatMessages = [];

  /// Saved components received from the backend.
  List<Map<String, dynamic>>? _savedComponents;

  /// Combine/condense operation status.
  String _combineStatus = '';
  String _combineStatusMessage = '';
  String? _combineError;

  // --- Reconnect state (T063/T064) ---
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _reconnectEnabled = true;

  /// Maximum reconnect delay in seconds.
  static const int maxReconnectDelaySec = 30;

  /// Last connection parameters, stored so we can auto-reconnect.
  String? _lastToken;
  Map<String, dynamic>? _lastDevice;
  List<String>? _lastCapabilities;
  String? _lastProjectId;

  bool get connected => _connected;
  String? get sessionId => _sessionId;
  String? get error => _error;
  List<Map<String, dynamic>> get components => _components;
  bool get hasReceivedRender => _hasReceivedRender;
  List<Map<String, dynamic>> get chatMessages =>
      List.unmodifiable(_chatMessages);
  List<Map<String, dynamic>>? get savedComponents => _savedComponents;
  String get combineStatus => _combineStatus;
  String get combineStatusMessage => _combineStatusMessage;
  String? get combineError => _combineError;

  /// Current reconnect attempt (exposed for testing).
  int get reconnectAttempt => _reconnectAttempt;

  @visibleForTesting
  set reconnectAttemptForTest(int value) => _reconnectAttempt = value;

  /// Whether auto-reconnect is enabled.
  bool get reconnectEnabled => _reconnectEnabled;
  set reconnectEnabled(bool value) => _reconnectEnabled = value;

  /// Connect to the AstralBody backend WebSocket.
  /// Token is optional — unauthenticated connections receive the SDUI login page.
  void connect({
    String? token,
    required Map<String, dynamic> device,
    required List<String> capabilities,
    String? projectId,
  }) {
    disconnect(triggeredByUser: true);

    // Store params for auto-reconnect (T063).
    _lastToken = token;
    _lastDevice = device;
    _lastCapabilities = capabilities;
    _lastProjectId = projectId;
    _reconnectAttempt = 0;

    _connectInternal(
      token: token,
      device: device,
      capabilities: capabilities,
      projectId: projectId,
    );
  }

  /// Internal connect used by both initial connect and auto-reconnect.
  void _connectInternal({
    String? token,
    required Map<String, dynamic> device,
    required List<String> capabilities,
    String? projectId,
  }) {
    try {
      // Connect without token in URL — auth is handled via register_ui message
      final wsUrl = projectId != null
          ? '${AppConfig.wsUrl}/stream/mcp:$projectId'
          : AppConfig.wsUrl;

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _connected = true;
      _error = null;

      // Send register_ui immediately, preserving session_id across reconnects.
      // Token is included if available (for reconnection with cached credentials).
      final registerMsg = {
        'type': 'register_ui',
        'capabilities': capabilities,
        'device': device,
        'token': ?token,
        if (_sessionId != null) 'session_id': _sessionId,
      };
      _channel!.sink.add(jsonEncode(registerMsg));

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (err) {
          _error = err.toString();
          _connected = false;
          notifyListeners();
          _startReconnect();
        },
        onDone: () {
          _connected = false;
          notifyListeners();
          _startReconnect();
        },
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _connected = false;
      notifyListeners();
      _startReconnect();
    }
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage as String);
      if (decoded is! Map<String, dynamic>) return;

      final type = decoded['type'];
      switch (type) {
        case 'ui_render':
          _handleUiRender(decoded);
          break;
        case 'ui_update':
          _handleUiUpdate(decoded);
          break;
        case 'ui_append':
          _handleUiAppend(decoded);
          break;
        case 'session_id':
          _sessionId = decoded['session_id'] as String?;
          break;
        case 'theme':
          // Theme updates are handled at the app level via a callback
          _onThemeReceived?.call(decoded['config'] as Map<String, dynamic>);
          break;
        case 'saved_components_list':
          _handleSavedComponentsList(decoded);
          break;
        case 'component_saved':
          _handleComponentSaved(decoded);
          break;
        case 'components_combined':
        case 'components_condensed':
          _handleComponentsMerged(decoded);
          break;
        case 'combine_status':
          _combineStatus = decoded['status'] as String? ?? '';
          _combineStatusMessage = decoded['message'] as String? ?? '';
          notifyListeners();
          break;
        case 'combine_error':
          _combineStatus = '';
          _combineError = decoded['error'] as String? ?? 'Unknown error';
          notifyListeners();
          break;
        case 'ui_action':
          _handleUiAction(decoded);
          break;
        case 'system_config':
          _onSystemConfig?.call(decoded);
          break;
        case 'history_list':
          _onHistoryList?.call(decoded);
          break;
        case 'chat_status':
          _onChatStatus?.call(decoded);
          break;
        case 'agent_registered':
          _onAgentRegistered?.call(decoded);
          break;
        // Backend informational messages — acknowledged but no UI action needed
        case 'rote_config':
        case 'user_preferences':
        case 'chat_created':
          _onChatCreated?.call(decoded);
          break;
        default:
          _logger.d('Unhandled WS message type: $type');
      }
    } catch (e) {
      _logger.e('Error parsing WS message', error: e);
    }
  }

  /// Full component tree replacement.
  void _handleUiRender(Map<String, dynamic> msg) {
    final raw = msg['components'];
    if (raw is List) {
      _components = raw.cast<Map<String, dynamic>>();
      _hasReceivedRender = true;
      _persistTree();
      notifyListeners();
    }
  }

  /// Partial update — replace components by matching id.
  void _handleUiUpdate(Map<String, dynamic> msg) {
    final updates = msg['components'];
    if (updates is! List) return;

    for (final update in updates) {
      if (update is! Map<String, dynamic>) continue;
      final id = update['id'];
      if (id == null) continue;
      _replaceComponentById(_components, id as String, update);
    }
    _persistTree();
    notifyListeners();
  }

  bool _replaceComponentById(
      List<Map<String, dynamic>> tree, String id, Map<String, dynamic> replacement) {
    for (var i = 0; i < tree.length; i++) {
      if (tree[i]['id'] == id) {
        tree[i] = replacement;
        return true;
      }
      // Recurse into children
      final children = tree[i]['children'];
      if (children is List) {
        if (_replaceComponentById(
            children.cast<Map<String, dynamic>>(), id, replacement)) {
          return true;
        }
      }
      // Recurse into content if it's a list of components
      final content = tree[i]['content'];
      if (content is List) {
        final compContent = content.whereType<Map<String, dynamic>>().toList();
        if (compContent.isNotEmpty &&
            _replaceComponentById(compContent, id, replacement)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Append data to a target component (used for chat streaming).
  void _handleUiAppend(Map<String, dynamic> msg) {
    final targetId = msg['target_id'] as String?;
    final data = msg['data'];
    if (data is Map<String, dynamic>) {
      _chatMessages.add(data);
    }
    if (targetId != null && data != null) {
      _appendToComponent(_components, targetId, data);
    }
    notifyListeners();
  }

  void _appendToComponent(
      List<Map<String, dynamic>> tree, String targetId, dynamic data) {
    for (final node in tree) {
      if (node['id'] == targetId) {
        if (node['children'] is List) {
          if (data is Map<String, dynamic>) {
            (node['children'] as List).add(data);
          }
        } else if (node['content'] is List) {
          (node['content'] as List).add(data);
        }
        return;
      }
      final children = node['children'];
      if (children is List) {
        _appendToComponent(
            children.cast<Map<String, dynamic>>(), targetId, data);
      }
    }
  }

  /// Send a ui_event to the backend.
  void sendEvent(String action, Map<String, dynamic> payload) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode({
      'type': 'ui_event',
      'action': action,
      'payload': payload,
      if (_sessionId != null) 'session_id': _sessionId,
    }));
  }

  /// Send raw data through the WebSocket.
  void send(dynamic data) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  /// Re-send register_ui with updated device dimensions (e.g. after rotation).
  void reRegister({
    String? token,
    required Map<String, dynamic> device,
    required List<String> capabilities,
  }) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode({
      'type': 'register_ui',
      'capabilities': capabilities,
      'device': device,
      'token': ?token,
      if (_sessionId != null) 'session_id': _sessionId,
    }));
  }

  // --- SDUI tree disk persistence (T014) ---

  static const _cacheKey = 'sdui_cached_tree';
  static const _savedCacheKey = 'sdui_cached_saved_components';

  Future<void> _persistTree() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_components));
    } catch (_) {}
  }

  Future<void> _persistSavedComponents() async {
    if (_savedComponents == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedCacheKey, jsonEncode(_savedComponents));
    } catch (_) {}
  }

  /// Load cached SDUI tree and saved components from disk (call on app startup).
  Future<void> loadCachedTree() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is List) {
          _components = decoded.cast<Map<String, dynamic>>();
          // Don't set _hasReceivedRender — this is stale cache
        }
      }
      final savedCached = prefs.getString(_savedCacheKey);
      if (savedCached != null) {
        final decoded = jsonDecode(savedCached);
        if (decoded is List) {
          _savedComponents = decoded.cast<Map<String, dynamic>>();
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  // --- Saved components handling ---

  void _handleSavedComponentsList(Map<String, dynamic> msg) {
    final raw = msg['components'];
    if (raw is List) {
      _savedComponents = raw.cast<Map<String, dynamic>>();
      _persistSavedComponents();
      notifyListeners();
    }
  }

  void _handleComponentSaved(Map<String, dynamic> msg) {
    final component = msg['component'];
    if (component is Map<String, dynamic>) {
      _savedComponents ??= [];
      _savedComponents!.add(component);
      _persistSavedComponents();
      notifyListeners();
    }
  }

  void _handleComponentsMerged(Map<String, dynamic> msg) {
    _combineStatus = '';
    _combineError = null;
    final removedIds = msg['removed_ids'] as List?;
    final newComponents = msg['new_components'] as List?;
    if (_savedComponents != null && removedIds != null) {
      _savedComponents!.removeWhere(
          (c) => removedIds.contains(c['id']));
    }
    if (newComponents != null) {
      _savedComponents ??= [];
      _savedComponents!.addAll(newComponents.cast<Map<String, dynamic>>());
    }
    _persistSavedComponents();
    notifyListeners();
  }

  // --- Theme callback ---

  void Function(Map<String, dynamic>)? _onThemeReceived;
  set onThemeReceived(void Function(Map<String, dynamic>)? callback) {
    _onThemeReceived = callback;
  }

  // --- UIAction callback (open_url, store_token, clear_token) ---

  void Function(String action, Map<String, dynamic> payload)? _onActionReceived;
  set onActionReceived(
      void Function(String action, Map<String, dynamic> payload)? callback) {
    _onActionReceived = callback;
  }

  // --- Shell data callbacks (system_config, history_list, chat_status) ---

  void Function(Map<String, dynamic>)? _onSystemConfig;
  set onSystemConfig(void Function(Map<String, dynamic>)? callback) {
    _onSystemConfig = callback;
  }

  void Function(Map<String, dynamic>)? _onHistoryList;
  set onHistoryList(void Function(Map<String, dynamic>)? callback) {
    _onHistoryList = callback;
  }

  void Function(Map<String, dynamic>)? _onChatStatus;
  set onChatStatus(void Function(Map<String, dynamic>)? callback) {
    _onChatStatus = callback;
  }

  void Function(Map<String, dynamic>)? _onAgentRegistered;
  set onAgentRegistered(void Function(Map<String, dynamic>)? callback) {
    _onAgentRegistered = callback;
  }

  void Function(Map<String, dynamic>)? _onChatCreated;
  set onChatCreated(void Function(Map<String, dynamic>)? callback) {
    _onChatCreated = callback;
  }

  void _handleUiAction(Map<String, dynamic> msg) {
    final action = msg['action'] as String? ?? '';
    final payload = msg['payload'] as Map<String, dynamic>? ?? {};
    _onActionReceived?.call(action, payload);
  }

  // --- Auto-reconnect with exponential backoff (T063/T064) ---

  /// Calculate the delay for the current reconnect attempt.
  /// Uses exponential backoff: 1s, 2s, 4s, 8s, 16s, capped at 30s.
  Duration reconnectDelay() {
    final delaySec = (1 << _reconnectAttempt).clamp(1, maxReconnectDelaySec);
    return Duration(seconds: delaySec);
  }

  /// Start the auto-reconnect timer. Called when connection is lost.
  void _startReconnect() {
    if (!_reconnectEnabled) return;
    if (_lastDevice == null || _lastCapabilities == null) {
      return;
    }

    _reconnectTimer?.cancel();
    final delay = reconnectDelay();
    _logger.i('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempt)');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempt++;
      _connectInternal(
        token: _lastToken,
        device: _lastDevice!,
        capabilities: _lastCapabilities!,
        projectId: _lastProjectId,
      );
    });
  }

  /// Cancel any pending reconnect timer.
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Disconnect and clean up resources.
  ///
  /// When [triggeredByUser] is true (explicit disconnect or new connect call),
  /// auto-reconnect is suppressed and stored connection params are cleared.
  void disconnect({bool triggeredByUser = false}) {
    _cancelReconnect();
    _subscription?.cancel();
    _channel?.sink.close(status.normalClosure);
    _channel = null;
    _connected = false;
    _hasReceivedRender = false;
    if (triggeredByUser) {
      _lastToken = null;
      _lastDevice = null;
      _lastCapabilities = null;
      _lastProjectId = null;
      _reconnectAttempt = 0;
    }
    notifyListeners();
  }

  // --- Test helpers ---

  /// Simulate receiving a raw WebSocket message. Exposed for unit tests only.
  @visibleForTesting
  void simulateMessage(String rawMessage) {
    _handleMessage(rawMessage);
  }

  @override
  void dispose() {
    disconnect(triggeredByUser: true);
    super.dispose();
  }
}
