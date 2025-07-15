import 'package:flutter/material.dart';
import 'package:version_controller/update_notification_widget.dart';
import 'package:version_controller/version_response_model.dart';
import 'package:version_controller/version_service.dart';

class UpdateWidget extends StatefulWidget {
  @override
  _UpdateWidgetState createState() => _UpdateWidgetState();
}

class _UpdateWidgetState extends State<UpdateWidget> {
  bool _updateAvailable = false;
  bool _downloaded = false;

  final _versionServer = VersionService('1');
  VersionResponse? versionParams;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final versionParams = await _versionServer.checkForUpdate();
      if ((versionParams.availableUpdate && versionParams.needUpdate)) {
        setState(
          () => _updateAvailable =
              (versionParams.availableUpdate && versionParams.needUpdate),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Check update = no update')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check update failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _downloadUpdate() async {
    try {
      await _versionServer.downloadUpdate(versionParams!.versionId);
      setState(() => _downloaded = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _installUpdate() async {
    try {
      await _versionServer.installUpdate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Installation failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_updateAvailable) return Container();

    return UpdateNotification(
      onUpdate: _downloaded ? _installUpdate : _downloadUpdate,
      isDownloaded: _downloaded,
    );
  }
}
