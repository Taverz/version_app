import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:version_app/models/platform_enum.dart';
import 'package:version_app/services/custom_server_service_dio.dart';

class UploadVersionScreen extends StatefulWidget {
  final String projectId;
  final CustomServerService supabaseService;

  const UploadVersionScreen({
    super.key,
    required this.projectId,
    required this.supabaseService,
  });

  @override
  State<UploadVersionScreen> createState() => _UploadVersionScreenState();
}

class _UploadVersionScreenState extends State<UploadVersionScreen>
    with UploadFileMixin {
  String? _selectedPlatform = PlatformType.android.name;
  final _versionNameController = TextEditingController(text: '1.0.0');
  bool _isUploading = false;

  @override
  void dispose() {
    _versionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Version'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isUploading ? null : () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _versionNameController,
              decoration: const InputDecoration(
                labelText: 'Version Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedPlatform,
              decoration: const InputDecoration(
                labelText: 'Platform',
                border: OutlineInputBorder(),
              ),
              items: PlatformType.values.map((platform) {
                return DropdownMenuItem<String>(
                  value: platform.name,
                  child: Text(platform.name),
                );
              }).toList(),
              onChanged: _isUploading
                  ? null
                  : (value) => setState(() => _selectedPlatform = value),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: _isUploading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.upload),
              label: Text(
                _isUploading ? 'Uploading...' : 'Select & Upload File',
              ),
              onPressed: _isUploading
                  ? null
                  : () => uploadFile(
                      context: context,
                      projectId: widget.projectId,
                      supabaseService: widget.supabaseService,
                      versionNameController: _versionNameController,
                      selectedPlatform: _selectedPlatform,
                      setIsUploading: (value) =>
                          setState(() => _isUploading = value),
                      getVersions: widget.supabaseService.getVersions,
                    ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

mixin UploadFileMixin {
  Future<void> uploadFile({
    required BuildContext context,
    required String projectId,
    required CustomServerService supabaseService,
    required TextEditingController versionNameController,
    required String? selectedPlatform,
    required void Function(bool) setIsUploading,
    required Future<void> Function(String) getVersions,
  }) async {
    if (versionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter version name')),
      );
      return;
    }

    setIsUploading(true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null) return;

      final file = result.files.first;
      final platforms = selectedPlatform != null
          ? [selectedPlatform]
          : <String>[];

      await supabaseService.uploadVersion(
        projectId: projectId,
        versionName: versionNameController.text,
        platforms: platforms,
        file: File.fromRawPath(file.bytes!),
        bytes: file.bytes,
        fileName: file.name,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Version uploaded successfully')),
        );
        await getVersions(projectId);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading version: $e')));
      }
    } finally {
      if (context.mounted) {
        setIsUploading(false);
      }
    }
  }
}
