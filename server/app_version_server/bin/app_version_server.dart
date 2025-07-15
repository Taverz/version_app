import 'dart:io';

import 'package:app_version_server/server.dart';

void main(List<String> arguments) {
  CustomServer(
    port: 8932,
    storagePath: '${Directory.current.path}/storage',
  ).start();
}
