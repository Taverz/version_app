import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:version_controller/server_parametr.dart';
import 'package:version_controller/version_response_model.dart';

class VersionService {
  final String applicationId;
  String? _downloadedApkPath;

  VersionService(this.applicationId);

  Future<VersionResponse> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(
          '${ServerParameter().YOUR_SERVER_URL}/checkUpdate/$applicationId/$currentVersion',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return VersionResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to check for updates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Update check failed: $e');
    }
  }

  Future<void> downloadUpdate(String versionId) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/update_$versionId.apk');

      final response = await http.get(
        Uri.parse(
          '${ServerParameter().YOUR_SERVER_URL}/download/$applicationId/$versionId',
        ),
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _downloadedApkPath = file.path;
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  Future<void> installUpdate() async {
    if (_downloadedApkPath == null) {
      throw Exception('No APK downloaded');
    }

    try {
      final result = await OpenFile.open(_downloadedApkPath!);
      if (result.type != ResultType.done) {
        throw Exception('Failed to install APK: ${result.message}');
      }
    } catch (e) {
      throw Exception('Installation failed: $e');
    }
  }

  /// Разрешение на установку: На Android 8+ запросите разрешение:
  void requestInstallPermission() async {
    // if (Platform.isAndroid) {
    //   await AndroidIntent(
    //     action: 'action_manage_unknown_app_sources',
    //     data: 'package:${context.packageName}',
    //   ).launch();
    // }
  }

  Future<void> downloadAndInstall(String url) async {
    final response = await http.get(Uri.parse(url));
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/app_update.apk');

    await file.writeAsBytes(response.bodyBytes);
    OpenFile.open(file.path);
  }
}
