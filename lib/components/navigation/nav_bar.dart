import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';
import '../../state/auth_provider.dart';

/// Responsive navigation bar for phone/tablet.
class NavBar extends StatelessWidget {
  final VoidCallback? onToggleControlPanel;

  const NavBar({super.key, this.onToggleControlPanel});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final projectName = projectProvider.currentProject?.name ?? 'No Project';

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1.5,
      titleSpacing: 16,
      title: Row(
        children: [
          Text(
            'AstralBody',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                projectName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.menu,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          onPressed: onToggleControlPanel,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.account_circle,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          onSelected: (value) {
            if (value == 'logout') {
              authProvider.logout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Text(authProvider.profile.username ?? 'Profile'),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
      ],
    );
  }
}
