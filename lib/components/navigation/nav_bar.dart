import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';

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
      backgroundColor: Colors.white,
      elevation: 1.5,
      titleSpacing: 16,
      title: Row(
        children: [
          Text('AI Interface', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(width: 16),
          Flexible(
            child: Builder(
              builder: (context) {
                final projectProvider = context.findAncestorWidgetOfExactType<MaterialApp>() != null
                    ? Provider.of<ProjectProvider>(context, listen: true)
                    : null;
                final projectName = projectProvider?.currentProject?.name ?? 'No Project';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    projectName,
                    style: TextStyle(color: Colors.blue[700], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.blueGrey),
          onPressed: widget.onToggleControlPanel,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, color: Colors.blueGrey),
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
