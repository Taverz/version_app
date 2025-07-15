import 'dart:async';
import 'dart:developer';
import 'package:app_version_server/src/handler/download_handler.dart';
import 'package:app_version_server/src/handler/project_handler.dart';
import 'package:app_version_server/src/handler/version_handler.dart';
import 'package:app_version_server/src/mappers/version_mappers.dart';
import 'package:app_version_server/src/utils/app_route_untils.dart';
import 'package:app_version_server/src/utils/file_until.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class CustomServer
    with
        VersionMapper,
        FileUntil,
        VersionHandler,
        ProjectHandler,
        AppRouterUtils,
        DownloadHandler {
  final int port;
  final String storagePath;

  CustomServer({required this.port, required this.storagePath});

  Future<void> start() async {
    final router = Router();

    // Projects API
    router.get('/projects', getAllProjects);
    router.post('/projects', createProject);
    router.get('/projects/<id>', getProject);
    router.put('/projects/<id>', updateProject);
    router.delete('/projects/<id>', deleteProject);
    // Versions API
    router.get('/versions/<projectId>', getVersions);
    router.delete('/versions/<versionId>', deleteVersion);
    router.post('/versions', uploadVersion);
    // File API
    router.post('/download', handleFileDownload);

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(handleCors)
        /// NO WORKED / NEED FIX
        // .addMiddleware(
        //   PrettyShelfLogger(
        //     debugMode: true,
        //     requestHeader: true,
        //     requestBody: true,
        //     responseBody: true,
        //   ).middleware,
        // )
        .addHandler(router);

    await io.serve(handler, '0.0.0.0', port);
    log(' 💥 Server running on port $port 🌈 ');
  }
}
