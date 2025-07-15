import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_version_server/src/data/local/database_service.dart';
import 'package:app_version_server/src/utils/file_until.dart';
import 'package:shelf/shelf.dart';

mixin DownloadHandler {
  Future<Response> handleFileDownload(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['filePath'] == null || data['filePath'].toString().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'No correct parameter, required filePath field',
          }),
        );
      }
      final filePath = data['filePath'];

      final file = File('$filePath');
      if (!await file.exists()) {
        return Response.notFound('File not found');
      }

      final fileStream = file.openRead();
      final contentType = UntilFile().getContentType(file.path);

      return Response.ok(
        fileStream,
        headers: {
          'Content-Type': contentType,
          'Content-Disposition':
              'attachment; filename="${file.path.split('/').last}"',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error downloading file');
    }
  }

  Future<Response> handleFileDownloadByProjectIdByVersion(
    Request request,
  ) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['projectId'] == null || data['projectId'].toString().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'No correct parameter, required projectId field',
          }),
        );
      }
      if (data['versionId'] == null || data['versionId'].toString().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'No correct parameter, required versionId field',
          }),
        );
      }
      final projectId = data['projectId'] as int;
      final versionId = data['versionId'] as String;

      final version = DatabaseService().getVersionByProjectId(
        projectId,
        versionId,
      );
      if (version == null) {
        return Response.notFound('Version not found');
      }

      if (version.downloadURL.toString().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'No correct parameter, required downloadURL field',
          }),
        );
      }
      final filePath = version.downloadURL;

      final file = File('$filePath');
      if (!await file.exists()) {
        return Response.notFound('File not found');
      }

      final fileStream = file.openRead();
      final contentType = UntilFile().getContentType(file.path);

      return Response.ok(
        fileStream,
        headers: {
          'Content-Type': contentType,
          'Content-Disposition':
              'attachment; filename="${file.path.split('/').last}"',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error downloading file');
    }
  }
}
