import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/web_socket_provider.dart';

/// Agent permissions bottom sheet with 4 scope cards (read/write/search/system),
/// expandable tool lists with toggles, and confirmation dialog.
///
/// Reads agent permissions from backend system_config and agent_registered
/// WebSocket messages.
class AgentPermissionsSheet extends StatefulWidget {
  final String agentId;
  final String agentName;
  final Map<String, dynamic> initialPermissions;

  const AgentPermissionsSheet({
    super.key,
    required this.agentId,
    required this.agentName,
    this.initialPermissions = const {},
  });

  /// Show the permissions sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String agentId,
    required String agentName,
    Map<String, dynamic> permissions = const {},
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => AgentPermissionsSheet(
          agentId: agentId,
          agentName: agentName,
          initialPermissions: permissions,
        ),
      ),
    );
  }

  @override
  State<AgentPermissionsSheet> createState() => _AgentPermissionsSheetState();
}

class _AgentPermissionsSheetState extends State<AgentPermissionsSheet> {
  late Map<String, bool> _scopeEnabled;
  late Map<String, List<_ToolEntry>> _toolsByScope;
  final Set<String> _expandedScopes = {};

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  void _initializePermissions() {
    final perms = widget.initialPermissions;
    final scopes = perms['scopes'] as Map<String, dynamic>? ?? {};
    _scopeEnabled = {
      'tools:read': scopes['tools:read'] as bool? ?? true,
      'tools:write': scopes['tools:write'] as bool? ?? false,
      'tools:search': scopes['tools:search'] as bool? ?? true,
      'tools:system': scopes['tools:system'] as bool? ?? false,
    };

    final tools = perms['tools'] as List? ?? [];
    _toolsByScope = {
      'tools:read': [],
      'tools:write': [],
      'tools:search': [],
      'tools:system': [],
    };
    for (final tool in tools) {
      final scope = tool['scope'] as String? ?? 'tools:read';
      final name = tool['name'] as String? ?? '';
      final enabled = tool['enabled'] as bool? ?? true;
      _toolsByScope[scope]?.add(_ToolEntry(name: name, enabled: enabled));
    }
  }

  Future<void> _toggleScope(String scope, bool value) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(value ? 'Enable Scope' : 'Disable Scope'),
        content: Text(
          value
              ? 'Enable ${_scopeLabel(scope)} for ${widget.agentName}?'
              : 'Disable ${_scopeLabel(scope)} for ${widget.agentName}? '
                  'All tools in this scope will be disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _scopeEnabled[scope] = value);
      _sendPermissionUpdate();
    }
  }

  void _toggleTool(String scope, int index, bool value) {
    setState(() {
      _toolsByScope[scope]![index] =
          _toolsByScope[scope]![index].copyWith(enabled: value);
    });
    _sendPermissionUpdate();
  }

  void _sendPermissionUpdate() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final permissions = <String, dynamic>{
      'agent_id': widget.agentId,
      'scopes': _scopeEnabled,
      'tools': _toolsByScope.entries
          .expand((e) => e.value.map((t) => {
                'scope': e.key,
                'name': t.name,
                'enabled': t.enabled,
              }))
          .toList(),
    };
    ws.sendEvent('update_agent_permissions', permissions);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text('Agent Permissions',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(widget.agentName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 16),

          // Scope cards
          Expanded(
            child: ListView(
              children: [
                _buildScopeCard(
                  scope: 'tools:read',
                  label: 'Read',
                  icon: Icons.visibility,
                  color: Colors.green,
                ),
                _buildScopeCard(
                  scope: 'tools:write',
                  label: 'Write',
                  icon: Icons.edit,
                  color: Colors.amber,
                ),
                _buildScopeCard(
                  scope: 'tools:search',
                  label: 'Search',
                  icon: Icons.search,
                  color: Colors.blue,
                ),
                _buildScopeCard(
                  scope: 'tools:system',
                  label: 'System',
                  icon: Icons.settings,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeCard({
    required String scope,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final enabled = _scopeEnabled[scope] ?? false;
    final tools = _toolsByScope[scope] ?? [];
    final isExpanded = _expandedScopes.contains(scope);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Scope header
          InkWell(
            onTap: tools.isNotEmpty
                ? () => setState(() {
                      if (isExpanded) {
                        _expandedScopes.remove(scope);
                      } else {
                        _expandedScopes.add(scope);
                      }
                    })
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text('${tools.length} tools',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (v) => _toggleScope(scope, v),
                    activeTrackColor: color.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected) ? color : null),
                  ),
                  if (tools.isNotEmpty)
                    Icon(
                      isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Theme.of(context).hintColor,
                    ),
                ],
              ),
            ),
          ),

          // Expandable tool list
          if (isExpanded && tools.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Column(
                children: [
                  const Divider(),
                  for (var i = 0; i < tools.length; i++)
                    _buildToolRow(scope, i, tools[i], enabled),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolRow(
      String scope, int index, _ToolEntry tool, bool scopeEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(tool.name,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch(
            value: tool.enabled && scopeEnabled,
            onChanged: scopeEnabled
                ? (v) => _toggleTool(scope, index, v)
                : null,
          ),
        ],
      ),
    );
  }

  String _scopeLabel(String scope) {
    switch (scope) {
      case 'tools:read':
        return 'Read';
      case 'tools:write':
        return 'Write';
      case 'tools:search':
        return 'Search';
      case 'tools:system':
        return 'System';
      default:
        return scope;
    }
  }
}

class _ToolEntry {
  final String name;
  final bool enabled;

  const _ToolEntry({required this.name, required this.enabled});

  _ToolEntry copyWith({String? name, bool? enabled}) =>
      _ToolEntry(name: name ?? this.name, enabled: enabled ?? this.enabled);
}
