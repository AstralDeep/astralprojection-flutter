import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_shell_provider.dart';
import '../../state/web_socket_provider.dart';
import '../theme/app_theme.dart';
import 'agent_card.dart';
import 'agent_permissions_sheet.dart';

/// Full-screen dialog listing all connected agents with tabs for
/// My Agents, Public Agents, and Drafts.
class AgentListDialog extends StatefulWidget {
  const AgentListDialog({super.key});

  @override
  State<AgentListDialog> createState() => _AgentListDialogState();
}

class _AgentListDialogState extends State<AgentListDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _a2aController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _a2aController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = Provider.of<AppShellProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isNarrow = screenSize.width < 600;

    final myAgents = shell.agents.where((a) => !a.isPublic).toList();
    final publicAgents = shell.agents.where((a) => a.isPublic).toList();

    return Dialog(
      backgroundColor: AstralColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 40,
        vertical: isNarrow ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(shell),
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AstralColors.primary,
                indicatorWeight: 2,
                labelColor: AstralColors.primary,
                unselectedLabelColor: AstralColors.text.withValues(alpha: 0.5),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'My Agents (${myAgents.length})'),
                  Tab(text: 'Public Agents (${publicAgents.length})'),
                  const Tab(text: 'Drafts'),
                ],
              ),
            ),

            // A2A URL input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: _a2aController,
                  style: TextStyle(fontSize: 12, color: AstralColors.text),
                  decoration: InputDecoration(
                    hintText: 'Register external A2A agent URL...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: AstralColors.text.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ),

            // Agent grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAgentGrid(myAgents, isNarrow),
                  _buildAgentGrid(publicAgents, isNarrow),
                  _buildEmptyDrafts(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppShellProvider shell) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AstralColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                size: 20, color: AstralColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AstralColors.text,
                  ),
                ),
                Text(
                  '${shell.agents.length} agents connected \u00b7 ${shell.totalTools} tools available',
                  style: TextStyle(
                    fontSize: 12,
                    color: AstralColors.text.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Add agent button
          IconButton(
            icon: const Icon(Icons.add, color: AstralColors.text),
            onPressed: () {},
            tooltip: 'Add Agent',
          ),
          IconButton(
            icon: Icon(Icons.close,
                color: AstralColors.text.withValues(alpha: 0.6)),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildAgentGrid(List<AgentInfo> agents, bool isNarrow) {
    if (agents.isEmpty) {
      return Center(
        child: Text(
          'No agents in this category',
          style: TextStyle(
            fontSize: 13,
            color: AstralColors.text.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    final crossAxisCount = isNarrow ? 1 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isNarrow ? 2.8 : 2.0,
      ),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        return AgentCard(
          agent: agent,
          onTap: () => _openPermissions(agent),
        );
      },
    );
  }

  Widget _buildEmptyDrafts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.drafts_outlined, size: 40,
              color: AstralColors.text.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'No draft agents yet',
            style: TextStyle(
              fontSize: 13,
              color: AstralColors.text.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _openPermissions(AgentInfo agent) {
    // Fetch latest permissions then open the sheet
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    ws.sendEvent('get_agent_permissions', {'agent_id': agent.id});

    AgentPermissionsSheet.show(
      context,
      agentId: agent.id,
      agentName: agent.name,
      permissions: {
        'scopes': agent.scopes,
        'tools': agent.tools
            .map((t) => {
                  'name': t,
                  'scope': agent.metadata['tool_scope_map']?[t] ?? 'tools:read',
                  'enabled': agent.permissions[t] ?? true,
                })
            .toList(),
      },
    );
  }
}
