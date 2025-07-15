import 'package:flutter/material.dart';
import 'package:version_controller/update_widget.dart';
import 'package:version_controller/version_response_model.dart';
import 'package:version_controller/version_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final versionServer = VersionService('1');
    return MaterialApp(
      title: 'Version Controller',
      home: Scaffold(
        body: Stack(
          children: [
            const Center(child: Text('Your App Content')),
            FutureBuilder<VersionResponse>(
              future: versionServer.checkForUpdate(),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data!.availableUpdate &&
                    snapshot.data!.needUpdate) {
                  return UpdateWidget();
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }
}
