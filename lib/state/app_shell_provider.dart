import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parsed agent info from system_config WebSocket message.
class AgentInfo {
  final String id;
  final String name;
  final String description;
  final List<String> tools;
  final Map<String, String> toolDescriptions;
  final Map<String, bool> scopes;
  final Map<String, bool> permissions;
  final String status;
  final String? ownerEmail;
  final bool isPublic;
  final Map<String, dynamic> metadata;

  const AgentInfo({
    required this.id,
    required this.name,
    this.description = '',
    this.tools = const [],
    this.toolDescriptions = const {},
    this.scopes = const {},
    this.permissions = const {},
    this.status = 'connected',
    this.ownerEmail,
    this.isPublic = false,
    this.metadata = const {},
  });

  factory AgentInfo.fromMap(Map<String, dynamic> m) {
    return AgentInfo(
      id: m['id'] as String? ?? m['agent_id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      description: m['description'] as String? ?? '',
      tools: (m['tools'] as List?)?.cast<String>() ?? [],
      toolDescriptions: (m['tool_descriptions'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
          {},
      scopes: (m['scopes'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v == true)) ??
          {},
      permissions: (m['permissions'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v == true)) ??
          {},
      status: m['status'] as String? ?? 'connected',
      ownerEmail: m['owner_email'] as String?,
      isPublic: m['is_public'] as bool? ?? false,
      metadata: m['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Parsed chat session from history_list WebSocket message.
class ChatSession {
  final String id;
  final String title;
  final DateTime? updatedAt;
  final String? preview;

  const ChatSession({
    required this.id,
    required this.title,
    this.updatedAt,
    this.preview,
  });

  factory ChatSession.fromMap(Map<String, dynamic> m) {
    DateTime? parsed;
    final raw = m['updated_at'];
    if (raw is String) {
      parsed = DateTime.tryParse(raw);
    }
    return ChatSession(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? 'Untitled',
      updatedAt: parsed,
      preview: m['preview'] as String?,
    );
  }
}

/// Provider for shell-level UI state: agents, chat history, sidebar toggle.
///
/// Fed by WebSocket callbacks wired in app.dart. Does not own the WS connection.
class AppShellProvider extends ChangeNotifier {
  static const _sidebarKey = 'sidebar_open';

  List<AgentInfo> _agents = [];
  int _totalTools = 0;
  List<ChatSession> _chatHistory = [];
  String _chatStatus = 'idle';
  String _chatStatusMessage = '';
  bool _sidebarOpen = true;
  String? _activeChatId;

  AppShellProvider() {
    _loadSidebarState();
  }

  Future<void> _loadSidebarState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_sidebarKey);
    if (saved != null && saved != _sidebarOpen) {
      _sidebarOpen = saved;
      notifyListeners();
    }
  }

  Future<void> _saveSidebarState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sidebarKey, _sidebarOpen);
  }

  // --- Getters ---

  List<AgentInfo> get agents => _agents;
  int get totalTools => _totalTools;
  List<ChatSession> get chatHistory => _chatHistory;
  String get chatStatus => _chatStatus;
  String get chatStatusMessage => _chatStatusMessage;
  bool get sidebarOpen => _sidebarOpen;
  String? get activeChatId => _activeChatId;

  // --- Update methods (called from WS callbacks) ---

  void updateFromSystemConfig(Map<String, dynamic> msg) {
    final config = msg['config'] as Map<String, dynamic>? ?? msg;
    final rawAgents = config['agents'] as List?;
    if (rawAgents != null) {
      _agents = rawAgents
          .whereType<Map<String, dynamic>>()
          .map(AgentInfo.fromMap)
          .toList();
    }
    _totalTools = config['total_tools'] as int? ?? _totalTools;
    notifyListeners();
  }

  void updateFromHistoryList(Map<String, dynamic> msg) {
    final rawChats = msg['chats'] as List?;
    if (rawChats != null) {
      _chatHistory = rawChats
          .whereType<Map<String, dynamic>>()
          .map(ChatSession.fromMap)
          .toList();
      notifyListeners();
    }
  }

  void updateChatStatus(Map<String, dynamic> msg) {
    _chatStatus = msg['status'] as String? ?? 'idle';
    _chatStatusMessage = msg['message'] as String? ?? '';
    notifyListeners();
  }

  void addOrUpdateAgent(Map<String, dynamic> msg) {
    final agent = AgentInfo.fromMap(msg);
    final idx = _agents.indexWhere((a) => a.id == agent.id);
    if (idx >= 0) {
      _agents[idx] = agent;
    } else {
      _agents.add(agent);
    }
    // Recount tools
    _totalTools = _agents.fold(0, (sum, a) => sum + a.tools.length);
    notifyListeners();
  }

  // --- UI state ---

  void toggleSidebar() {
    _sidebarOpen = !_sidebarOpen;
    _saveSidebarState();
    notifyListeners();
  }

  void setSidebarOpen(bool open) {
    if (_sidebarOpen != open) {
      _sidebarOpen = open;
      _saveSidebarState();
      notifyListeners();
    }
  }

  void setActiveChatId(String? id) {
    if (_activeChatId != id) {
      _activeChatId = id;
      notifyListeners();
    }
  }
}
