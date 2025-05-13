import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';
import '../../state/auth_provider.dart';
import '../common/loading_spinner.dart';

class ProjectDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final projects = projectProvider.projects;
    final currentProject = projectProvider.currentProject;
    final isLoading = projectProvider.isLoading;
    final error = projectProvider.error;
    final token = authProvider.token;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Project>(
                value: currentProject,
                hint: const Text('Select Project'),
                items: projects.map((project) {
                  return DropdownMenuItem<Project>(
                    value: project,
                    child: Text(project.name),
                  );
                }).toList(),
                onChanged: (project) {
                  if (project != null) {
                    projectProvider.switchProject(project.id);
                  }
                },
                underline: const SizedBox(),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, color: Color(0xFF4A5CF0)),
                tooltip: 'Refresh Projects',
                onPressed: isLoading || token == null
                    ? null
                    : () => projectProvider.loadProjectsFromBackend(token),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        if (!isLoading && projects.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('No projects found.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ),
      ],
    );
  }
}
