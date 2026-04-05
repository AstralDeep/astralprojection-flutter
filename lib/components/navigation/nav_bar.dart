import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/device_profile_provider.dart';
import '../../state/web_socket_provider.dart';
import '../theme/app_theme.dart';

/// Responsive top navigation bar.
///
/// Desktop/tablet: Dashboard icon+text (left) | AstralDeep logo+text + hamburger (right).
/// Mobile: hamburger button only.
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DeviceProfileProvider>(context);
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final isMobile = dp.isMobile;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AstralColors.background.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: isMobile
                  ? _buildMobileNav(context)
                  : _buildDesktopNav(context, ws),
            ),
          ),
        ),
      ),
    );
  }

  /// Mobile: just a hamburger button
  Widget _buildMobileNav(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        IconButton(
          icon: Icon(Icons.menu,
              color: AstralColors.text.withValues(alpha: 0.7)),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menu',
        ),
      ],
    );
  }

  /// Desktop/tablet: Dashboard left | + New Chat right
  Widget _buildDesktopNav(BuildContext context, WebSocketProvider ws) {
    return Row(
      children: [
        // Left: Dashboard icon + text
        Icon(Icons.dashboard_outlined,
            size: 20, color: AstralColors.text.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AstralColors.text.withValues(alpha: 0.9),
          ),
        ),

        const Spacer(),

        // Right: + New Chat button
        _NewChatButton(onPressed: () => ws.sendEvent('new_chat', {})),
      ],
    );
  }
}

class _NewChatButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _NewChatButton({required this.onPressed});

  @override
  State<_NewChatButton> createState() => _NewChatButtonState();
}

class _NewChatButtonState extends State<_NewChatButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? AstralColors.primary.withValues(alpha: 0.2)
                : AstralColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AstralColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AstralColors.primary),
              SizedBox(width: 6),
              Text(
                'New Chat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AstralColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
