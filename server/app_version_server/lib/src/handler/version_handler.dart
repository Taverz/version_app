import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_version_server/src/data/local/database_service.dart';
import 'package:app_version_server/src/mappers/version_mappers.dart';
import 'package:app_version_server/src/models/version_model.dart';
import 'package:app_version_server/src/utils/file_until.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';

mixin VersionHandler on FileUntil, VersionMapper {
  Future<Response> getVersions(Request request, String projectId) async {
    try {
      final pid = int.tryParse(projectId);
      if (pid == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid project ID'}),
        );
      }

      final db = DatabaseService();
      final versions = db.getVersionsByProjectId(pid);

      final responseData = versions.map(mapVersionData).toList();

      return Response.ok(
        jsonEncode(responseData),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      log('Error getting versions: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get versions'}),
      );
    }
  }

  Future<Response> deleteVersion(Request request, String versionId) async {
    final db = DatabaseService();

    try {
      final version = await db.getVersionById(versionId);
      if (version == null) {
        return Response.notFound(jsonEncode({'error': 'Version not found'}));
      }
      final filePath = getFilePathFromUrl(version['downloadURL'] as String);
      final fileDeleted = await deleteFile(filePath);

      final dbDeleted = await db.deleteVersion(versionId);

      if (!dbDeleted) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to delete version from database'}),
        );
      }

      return Response.ok(
        jsonEncode({
          'status': 'deleted',
          'versionId': versionId,
          'fileDeleted': fileDeleted,
        }),
      );
    } catch (e, stackTrace) {
      log('Error deleting version: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete version'}),
      );
    }
  }

  Future<Response> uploadVersion(Request request) async {
    try {
      final storageDir = Directory('storage');
      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
      }

      final bodyBytes = await request.read().expand((chunk) => chunk).toList();
      if (bodyBytes.isEmpty) {
        return Response.badRequest(body: 'Empty request body');
      }

      final contentType = request.headers['content-type'];
      if (contentType == null ||
          !contentType.startsWith('multipart/form-data')) {
        return Response.badRequest(body: 'Invalid Content-Type');
      }

      final boundary = getBoundary(contentType);
      if (boundary.isEmpty) {
        return Response.badRequest(body: 'Missing boundary');
      }

      final stream = Stream.fromIterable([bodyBytes]);
      final transformer = MimeMultipartTransformer(boundary);
      final parts = await transformer.bind(stream).toList();

      String? projectId;
      String? versionName;
      List<String>? platforms;
      Uint8List? fileBytes;
      String? fileName;

      for (final part in parts) {
        final contentDisposition = part.headers['content-disposition'] ?? '';
        final content = await part.fold(
          <int>[],
          (List<int> accumulator, List<int> data) => accumulator..addAll(data),
        );

        if (contentDisposition.contains('name="projectId"')) {
          projectId = utf8.decode(content);
        } else if (contentDisposition.contains('name="versionName"')) {
          versionName = utf8.decode(content);
        } else if (contentDisposition.contains('name="platforms"')) {
          platforms = utf8.decode(content).split(',');
        } else if (contentDisposition.contains('name="file"')) {
          fileBytes = Uint8List.fromList(content);
          fileName = extractFilename(contentDisposition);
        }
      }

      if (projectId == null ||
          versionName == null ||
          fileBytes == null ||
          fileName == null) {
        return Response.badRequest(body: 'Missing required fields');
      }

      final versionsDir = Directory('storage/versions');
      if (!await versionsDir.exists()) {
        await versionsDir.create(recursive: true);
      }

      final savedFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final filePath = 'storage/versions/$savedFileName';
      await File(filePath).writeAsBytes(fileBytes);

      final db = DatabaseService();
      final versionId = DateTime.now().millisecondsSinceEpoch.toString();
      final versionData = Version(
        id: versionId,
        projectId: int.parse(projectId),
        versionName: versionName,
        platforms: platforms ?? [],
        downloadURL: '/storage/versions/$savedFileName',
        createdAt: DateTime.now(),
      );

      final success = db.createVersion(versionData.toMap());

      if (!success) {
        await File(filePath).delete();
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to save version to database'}),
        );
      }

      return Response.ok(
        jsonEncode({"result": versionData.toMap(), "status": "success"}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      log('Error uploading version: $e\n$stackTrace');
      return Response.internalServerError(body: 'Error uploading version');
    }
  }
}
