import 'dart:convert';

import 'package:meta/meta.dart';

@immutable
class Version {
  final String id;
  final int projectId;
  final String versionName;
  final List<String> platforms;
  final String downloadURL;
  final DateTime createdAt;

  const Version({
    required this.id,
    required this.projectId,
    required this.versionName,
    required this.platforms,
    required this.downloadURL,
    required this.createdAt,
  });

  factory Version.fromMap(Map<String, dynamic> map) {
    return Version(
      id: map['id'] as String,
      projectId: map['projectId'] as int,
      versionName: map['versionName'] as String,
      platforms: map['platforms'] is String
          ? List<String>.from(
              jsonDecode(map['platforms'] as String) as List<dynamic>,
            )
          : List<String>.from(map['platforms'] as List<dynamic>),
      downloadURL: map['downloadURL'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'versionName': versionName,
      'platforms': jsonEncode(platforms),
      'downloadURL': downloadURL,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Version copyWith({
    String? id,
    int? projectId,
    String? versionName,
    List<String>? platforms,
    String? downloadURL,
    DateTime? createdAt,
  }) {
    return Version(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      versionName: versionName ?? this.versionName,
      platforms: platforms ?? this.platforms,
      downloadURL: downloadURL ?? this.downloadURL,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
