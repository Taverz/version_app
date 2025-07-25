import 'package:flutter/material.dart';
import 'package:version_app/screens/projects_list.dart';
import 'package:version_app/services/server_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App Hosting',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: ProjectsListScreen(supabaseService: ConfigServer().dartServer),
    );
  }
}
