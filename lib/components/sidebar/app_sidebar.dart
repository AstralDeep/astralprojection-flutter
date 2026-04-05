import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_shell_provider.dart';
import '../../state/web_socket_provider.dart';
import '../theme/app_theme.dart';
import '../agents/agent_list_dialog.dart';
import 'chat_history_tile.dart';

/// Responsive sidebar matching the React frontend's DashboardLayout.
///
/// On desktop: persistent sidebar (256px expanded / 64px collapsed).
/// On mobile/tablet: used as a Drawer overlay.
class AppSidebar extends StatefulWidget {
  /// Whether the sidebar is in collapsed icon-rail mode (desktop only).
  final bool collapsed;

  /// Called when the user taps the hamburger to toggle collapse (desktop)
  /// or close (mobile).
  final VoidCallback? onToggle;

  /// Whether this is rendered inside a Drawer (mobile/tablet).
  final bool isDrawer;

  const AppSidebar({
    super.key,
    this.collapsed = false,
    this.onToggle,
    this.isDrawer = false,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = Provider.of<AppShellProvider>(context);
    final ws = Provider.of<WebSocketProvider>(context);

    final sidebarWidth = widget.collapsed ? 64.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isDrawer ? 280 : sidebarWidth,
      decoration: BoxDecoration(
        color: AstralColors.surface.withValues(alpha: 0.3),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: SafeArea(
        child: widget.collapsed
            ? _buildCollapsedRail(shell, ws)
            : _buildExpandedContent(shell, ws),
      ),
    );
  }

  /// Collapsed icon rail for desktop mode.
  Widget _buildCollapsedRail(AppShellProvider shell, WebSocketProvider ws) {
    return Column(
      children: [
        // Logo area
        SizedBox(
          height: 56,
          child: Center(
            child: Image.asset('assets/icon/astra-fav.png', width: 32, height: 32),
          ),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
        const SizedBox(height: 8),
        // Expand button
        _railIcon(Icons.menu, 'Expand', onTap: widget.onToggle),
        const SizedBox(height: 4),
        // New Chat
        _railIcon(Icons.add, 'New Chat', onTap: () {
          ws.sendEvent('new_chat', {});
        }),
        const SizedBox(height: 4),
        // Agents
        _railIcon(Icons.smart_toy_outlined, 'Agents', onTap: () {
          _openAgentList(context);
        }),
        const Spacer(),
        // Connection status dot
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Tooltip(
            message: ws.connected ? 'Connected' : 'Disconnected',
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ws.connected ? Colors.green : Colors.red,
              ),
            ),
          ),
        ),
        // Sign out
        _railIcon(Icons.logout, 'Sign Out', onTap: () {
          ws.sendEvent('logout', {});
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _railIcon(IconData icon, String tooltip, {VoidCallback? onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 22, color: AstralColors.text.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  /// Full expanded sidebar content.
  Widget _buildExpandedContent(AppShellProvider shell, WebSocketProvider ws) {
    final filteredChats = _searchQuery.isEmpty
        ? shell.chatHistory
        : shell.chatHistory
            .where((c) =>
                c.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: logo + hamburger
        _buildHeader(),
        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

        // Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // STATUS section
              _buildSectionLabel('STATUS'),
              const SizedBox(height: 4),
              _buildStatusItem(
                icon: ws.connected ? Icons.wifi : Icons.wifi_off,
                label: 'Orchestrator',
                value: ws.connected ? 'Connected' : 'Reconnecting...',
                color: ws.connected ? Colors.green : Colors.amber,
              ),
              _buildStatusItem(
                icon: Icons.smart_toy_outlined,
                label: 'Agents',
                value: '${shell.agents.length} active',
                color: AstralColors.accent,
              ),
              _buildStatusItem(
                icon: Icons.build_outlined,
                label: 'Tools',
                value: '${shell.totalTools} available',
                color: AstralColors.secondary,
              ),
              const SizedBox(height: 16),

              // Agents button
              _buildAgentsButton(shell),
              const SizedBox(height: 16),

              // RECENT CHATS section
              _buildSectionLabel('RECENT CHATS'),
              const SizedBox(height: 8),

              // Search bar (if >3 chats)
              if (shell.chatHistory.length > 3) ...[
                _buildSearchBar(),
                const SizedBox(height: 8),
              ],

              // Chat list
              if (filteredChats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _searchQuery.isEmpty ? 'No history yet...' : 'No matches',
                    style: TextStyle(
                      fontSize: 12,
                      color: AstralColors.text.withValues(alpha: 0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                for (final chat in filteredChats)
                  ChatHistoryTile(
                    chat: chat,
                    isActive: shell.activeChatId == chat.id,
                    onTap: () {
                      shell.setActiveChatId(chat.id);
                      ws.sendEvent('load_chat', {'chat_id': chat.id});
                      if (widget.isDrawer) Navigator.of(context).pop();
                    },
                    onDelete: () {
                      ws.sendEvent('delete_chat', {'chat_id': chat.id});
                    },
                  ),
            ],
          ),
        ),

        // Footer: Sign Out
        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () => ws.sendEvent('logout', {}),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18,
                      color: AstralColors.text.withValues(alpha: 0.6)),
                  const SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 13,
                      color: AstralColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Full logo with text — only shown when expanded
            Expanded(
              child: Image.asset(
                'assets/icon/AstralDeep.png',
                height: 24,
                alignment: Alignment.centerLeft,
              ),
            ),
            IconButton(
              icon: Icon(
                widget.isDrawer ? Icons.close : Icons.menu,
                size: 20,
                color: AstralColors.text.withValues(alpha: 0.6),
              ),
              onPressed: widget.isDrawer
                  ? () => Navigator.of(context).pop()
                  : widget.onToggle,
              tooltip: widget.isDrawer ? 'Close' : 'Collapse',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: AstralColors.text.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AstralColors.text.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsButton(AppShellProvider shell) {
    return InkWell(
      onTap: () => _openAgentList(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.smart_toy_outlined, size: 18,
                color: AstralColors.text.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Text(
              'Agents',
              style: TextStyle(
                fontSize: 13,
                color: AstralColors.text,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AstralColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${shell.agents.length} connected',
                style: TextStyle(
                  fontSize: 10,
                  color: AstralColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18,
                color: AstralColors.text.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontSize: 12, color: AstralColors.text),
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: AstralColors.text.withValues(alpha: 0.3),
          ),
          prefixIcon: Icon(Icons.search, size: 16,
              color: AstralColors.text.withValues(alpha: 0.3)),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(Icons.close, size: 14,
                      color: AstralColors.text.withValues(alpha: 0.3)),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 32),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
      ),
    );
  }

  void _openAgentList(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AgentListDialog(),
    );
  }
}
