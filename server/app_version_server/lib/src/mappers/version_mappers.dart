import 'dart:convert';

mixin VersionMapper {
  Map<String, dynamic> mapVersionData(Map<String, dynamic> version) {
    return {
      'id': version['id'],
      'versionName': version['versionName'],
      'platforms': version['platforms'] is String
          ? ((version['platforms'] as String?) == null
                ? null
                : jsonDecode(version['platforms'] as String))
          : List<String>.from(version['platforms'] as List<dynamic>),
      'downloadURL': version['downloadURL'],
      'createdAt': version['createdAt'],
      'fileExists': (version['downloadURL'] as String?) == null
          ? null
          : version['downloadURL'].toString(),
    };
  }
}
