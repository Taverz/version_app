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
import 'package:pub_semver/pub_semver.dart' as version_parse;
import 'package:shelf/shelf.dart';

mixin VersionHandler on FileUntil, VersionMapper {
  /// ### GET - /checkUpdate/$projectId/$currentVersion (currentVersion - version install on client)
  /// #### Result request, Map, contains parameter:
  /// * last-version: (1.2.3+32-beta/1.2.3)
  /// * needUpdate: (true/false)
  /// * availableUpdate: (true/false)
  /// * reinstallNeed: (true/false) - major update / minor update (reinstall - delete application before install new version)
  Response checkUpdate(
    Request request,
    String projectId,
    String currentVersion,
  ) {
    log(
      '''Check update for project $projectId with current version $currentVersion''',
    );

    final lastVersion = DatabaseService().getLastVersionByProjectId(
      int.parse(projectId),
    );
    if (lastVersion == null) {
      return Response.ok(
        jsonEncode({
          'status': 'not found',
          'last-version': null,
          'versionId': null,
          'version': null,
          'needUpdate': false,
          'availableUpdate': false,
          'reinstallNeed': false,
        }),
      );
    }
    final currentSemVer = version_parse.Version.parse(currentVersion);
    final lastSemVer = version_parse.Version.parse(lastVersion.versionName);
    if (currentSemVer > lastSemVer) {
      return Response.ok(
        jsonEncode({
          'status': 'OK',
          'last-version': lastVersion.versionName,
          'versionId': lastVersion.id,
          'version': lastVersion.toMap(),
          'needUpdate': true,
          'availableUpdate': false,
          'reinstallNeed': false,
        }),
      );
    } else {
      return Response.ok(
        jsonEncode({
          'status': 'OK',
          'last-version': lastVersion.versionName,
          'versionId': lastVersion.id,
          'version': lastVersion.toMap(),
          'needUpdate': false,
          'availableUpdate': false,
          'reinstallNeed': false,
        }),
      );
    }
  }

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
      // ignore: avoid_slow_async_io
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
      // ignore: avoid_slow_async_io
      if (!await versionsDir.exists()) {
        await versionsDir.create(recursive: true);
      }

      final savedFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final filePath = 'storage/versions/$savedFileName';
      await File(filePath).writeAsBytes(fileBytes);

      final db = DatabaseService();
      final versionId = DateTime.now().millisecondsSinceEpoch.toString();
      final versionData = VersionApp(
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
        jsonEncode({'result': versionData.toMap(), 'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      log('Error uploading version: $e\n$stackTrace');
      return Response.internalServerError(body: 'Error uploading version');
    }
  }
}
