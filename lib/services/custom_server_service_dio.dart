import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:universal_html/html.dart' as html;
import 'package:mime/mime.dart';
import 'package:version_app/models/project_model.dart';
import 'package:version_app/models/version_model.dart';

class CustomServerService {
  final Dio dio;
  final StreamController<List<Project>> _getAllProjectsStreamController =
      StreamController<List<Project>>.broadcast();
  Stream<List<Project>> get getAllProjectsStream =>
      _getAllProjectsStreamController.stream;

  final StreamController<List<Version>> _getAllVersionStreamController =
      StreamController<List<Version>>.broadcast();
  Stream<List<Version>> get getAllVersionStream =>
      _getAllVersionStreamController.stream;

  CustomServerService({required this.dio});

  void dispose() {
    _getAllProjectsStreamController.close();
  }

  Future<void> getAllProjectsUpdate() async {
    try {
      final projects = await _getAllProjects();
      _getAllProjectsStreamController.add(projects);
    } catch (e) {
      _getAllProjectsStreamController.addError(e);
    }
  }

  Future<List<Project>> _getAllProjects() async {
    final response = await dio.get('/projects');
    if (response.statusCode == 200) {
      return (response.data as List)
          .map((p) => Project.fromMap(p as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load projects: ${response.statusMessage}');
    }
  }

  Future<Project> createProject(Project project) async {
    final response = await dio.post(
      '/projects',
      data: project.toMap(),
      options: Options(contentType: 'application/json'),
    );

    if (response.statusCode == 200) {
      await getAllProjectsUpdate();
      return project;
    } else {
      throw Exception('Failed to create project: ${response.statusMessage}');
    }
  }

  Future<Project> getProject(int id) async {
    final response = await dio.get('/projects/$id');
    if (response.statusCode == 200) {
      return Project.fromMap(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load project: ${response.statusMessage}');
    }
  }

  Future<void> updateProject(
    int id, {
    String? name,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    await dio.put(
      '/projects/$id',
      data: updates,
      options: Options(contentType: 'application/json'),
    );
  }

  Future<void> deleteProject(int id) async {
    await dio.delete('/projects/$id');
  }

  Future<List<Version>> getVersions(String projectId) async {
    final response = await dio.get('/versions/$projectId');
    if (response.statusCode == 200) {
      final value = (response.data as List)
          .map((json) => Version.fromMap(json as Map<String, dynamic>))
          .toList();
      _getAllVersionStreamController.add(value);
      return value;
    } else {
      throw Exception('Failed to load versions: ${response.statusMessage}');
    }
  }

  Future<void> deleteVersion(String versionId) async {
    await dio.delete('/versions/$versionId');
  }

  Future<void> downloadVersion(
    String filePath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      log('start download');
      if (kIsWeb) {
        // Web implementation with error handling
        final response = await dio.post(
          '/download',
          data: jsonEncode({"filePath": filePath.replaceFirst('/', '')}),
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Content-Type': 'application/octet-stream'},
            validateStatus: (status) => status == 200,
          ),
          onReceiveProgress: (received, total) {
            if (onProgress != null && total > 0) {
              onProgress(received / total * 100);
            }
          },
        );

        if (response.statusCode == 200) {
          final bytes = response.data as List<int>;
          final base64 = base64Encode(bytes);
          final mimeType =
              lookupMimeType(filePath) ?? 'application/octet-stream';
          final url = 'data:$mimeType;base64,$base64';

          html.AnchorElement(href: url)
            ..setAttribute('download', filePath.split('/').last)
            ..click();
        } else {
          throw Exception('File not found (404)');
        }
      } else {
        // Native implementation
        await dio.download(
          '/download',
          filePath,
          data: jsonEncode({"filePath": filePath}),
          onReceiveProgress: (received, total) {
            if (onProgress != null && total > 0) {
              onProgress(received / total * 100);
            }
          },
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Content-Type': 'application/octet-stream'},
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to download version: $e');
    }
  }

  Future<void> uploadVersion({
    required String projectId,
    required String versionName,
    required List<String> platforms,
    File? file,
    Uint8List? bytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      const isWeb = kIsWeb;
      final formData = FormData.fromMap({
        'projectId': projectId,
        'versionName': versionName,
        'platforms': platforms.join(','),
        'file': isWeb
            ? MultipartFile.fromBytes(
                bytes!.toList(),
                filename: fileName,
                contentType: MediaType(
                  'application',
                  'vnd.android.package-archive',
                ),
              )
            : MultipartFile.fromFileSync(
                file!.path,
                filename: fileName,
                contentType: MediaType(
                  'application',
                  'vnd.android.package-archive',
                ),
              ),
      });

      await dio.post(
        '/versions',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total * 100);
          }
        },
      );
    } catch (e) {
      throw Exception('Ошибка загрузки версии: $e');
    }
  }
}
