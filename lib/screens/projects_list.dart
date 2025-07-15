import 'package:flutter/material.dart';
import 'package:version_app/models/project_model.dart';
import 'package:version_app/screens/versions_list.dart';
import 'package:version_app/services/custom_server_service_dio.dart';

class ProjectsListScreen extends StatefulWidget {
  final CustomServerService supabaseService;

  const ProjectsListScreen({super.key, required this.supabaseService});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  @override
  void initState() {
    widget.supabaseService.getAllProjectsUpdate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: StreamBuilder<List<Project>>(
        stream: widget.supabaseService.getAllProjectsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading projects'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return const Center(child: Text('Empti List PORJECT'));
          }
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                child: ListTile(
                  title: Text(project.name),
                  subtitle: Text(project.description),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VersionsListScreen(
                          projectId: project.id.toString(),
                          supabaseService: widget.supabaseService,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final project = Project(
                    id: UniqueKey().hashCode,
                    name: nameController.text,
                    description: descController.text,
                    createdAt: DateTime.now(),
                  );
                  await widget.supabaseService.createProject(project);
                  await widget.supabaseService.getAllProjectsUpdate();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating project: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
