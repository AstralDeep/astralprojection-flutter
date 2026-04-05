import 'package:flutter/material.dart';
import '../../state/app_shell_provider.dart';
import '../theme/app_theme.dart';

/// Card widget displaying a single agent in the agent list dialog.
class AgentCard extends StatefulWidget {
  final AgentInfo agent;
  final VoidCallback onTap;

  const AgentCard({
    super.key,
    required this.agent,
    required this.onTap,
  });

  @override
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;

    // Determine status dot color based on scope state
    final enabledScopes = agent.scopes.values.where((v) => v).length;
    final Color statusColor;
    if (enabledScopes == 0) {
      statusColor = Colors.red;
    } else if (enabledScopes < 4) {
      statusColor = Colors.amber;
    } else {
      statusColor = Colors.green;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon + name + badges + chevron
              Row(
                children: [
                  // Agent icon with status dot
                  Stack(
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
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AstralColors.surface, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Name + badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AstralColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Scope badges
                            _scopeBadge(statusColor, enabledScopes),
                            const SizedBox(width: 6),
                            if (agent.isPublic) _publicBadge(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18,
                      color: AstralColors.text.withValues(alpha: 0.3)),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              if (agent.description.isNotEmpty)
                Text(
                  agent.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AstralColors.text.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              // Tool count
              Row(
                children: [
                  Icon(Icons.build_outlined, size: 12,
                      color: AstralColors.text.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    '${agent.tools.length} tools active',
                    style: TextStyle(
                      fontSize: 11,
                      color: AstralColors.text.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scopeBadge(Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count/4',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _publicBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public, size: 9, color: Colors.green),
          SizedBox(width: 2),
          Text(
            'Public',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.green),
          ),
        ],
      ),
    );
  }
}
