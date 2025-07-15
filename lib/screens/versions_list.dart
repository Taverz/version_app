import 'package:flutter/material.dart';
import 'package:version_app/models/version_model.dart';
import 'package:version_app/screens/upload_version.dart';
import 'package:version_app/services/custom_server_service_dio.dart';

class VersionsListScreen extends StatefulWidget {
  final String projectId;
  final CustomServerService supabaseService;

  const VersionsListScreen({
    super.key,
    required this.projectId,
    required this.supabaseService,
  });

  @override
  State<VersionsListScreen> createState() => _VersionsListScreenState();
}

class _VersionsListScreenState extends State<VersionsListScreen> {
  @override
  void initState() {
    _loadVersions();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VersionsListScreen oldWidget) {
    _loadVersions();
    super.didUpdateWidget(oldWidget);
  }

  void _loadVersions() {
    widget.supabaseService.getVersions(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Versions')),
      body: StreamBuilder<List<Version>>(
        stream: widget.supabaseService.getAllVersionStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final versions = snapshot.data!;
          if (versions.isEmpty) {
            return const Center(child: Text('No versions available'));
          }

          return ListView.builder(
            itemCount: versions.length,
            itemBuilder: (context, index) {
              final version = versions[index];
              return Card(
                child: ListTile(
                  title: Text(version.versionName ?? 'No name'),
                  subtitle: Text(version.platforms?.join(', ') ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (version.downloadURL != null)
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            widget.supabaseService.downloadVersion(
                              version.downloadURL!,
                              onProgress: (value) {},
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteVersion(context, version.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadVersionScreen(
                projectId: widget.projectId,
                supabaseService: widget.supabaseService,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteVersion(BuildContext context, String versionId) async {
    try {
      await widget.supabaseService.deleteVersion(versionId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Version deleted')));
        _loadVersions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting version: $e')));
      }
    }
  }
}
