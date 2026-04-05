import 'package:flutter/material.dart';
import '../../state/app_shell_provider.dart';
import '../theme/app_theme.dart';

/// Single chat entry in the sidebar's recent chats list.
class ChatHistoryTile extends StatefulWidget {
  final ChatSession chat;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ChatHistoryTile({
    super.key,
    required this.chat,
    this.isActive = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<ChatHistoryTile> createState() => _ChatHistoryTileState();
}

class _ChatHistoryTileState extends State<ChatHistoryTile> {
  bool _hovered = false;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onDelete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AstralColors.primary.withValues(alpha: 0.15)
                : _hovered
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: widget.isActive
                    ? AstralColors.primary
                    : AstralColors.text.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: AstralColors.text,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.chat.updatedAt != null)
                      Text(
                        _formatDate(widget.chat.updatedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AstralColors.text.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
              if (_hovered && widget.onDelete != null)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AstralColors.text.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
