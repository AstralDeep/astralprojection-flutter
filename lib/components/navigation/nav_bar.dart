import 'package:flutter/material.dart';

class NavBar extends StatefulWidget {
  final VoidCallback? onToggleControlPanel;

  const NavBar({Key? key, this.onToggleControlPanel}) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  bool isUserMenuOpen = false;
  bool isProjectMenuOpen = false;

  // TODO: Integrate with state management for profile, projects, etc.

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Project Name'), // TODO: Bind to current project name
      actions: [
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onToggleControlPanel,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            // TODO: Handle user menu actions
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Text('Profile'),
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
