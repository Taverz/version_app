import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
}
