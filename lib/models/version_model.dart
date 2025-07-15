import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class Version {
  final String id;
  final String? projectId;
  final String? versionName;
  final List<String>? platforms;
  final String? downloadURL;
  final DateTime? createdAt;

  const Version({
    required this.id,
    required this.projectId,
    required this.versionName,
    required this.platforms,
    required this.downloadURL,
    required this.createdAt,
  });

  Version copyWith({
    String? id,
    String? projectId,
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'projectId': projectId,
      'versionName': versionName,
      'platforms': platforms,
      'downloadURL': downloadURL,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Version.fromMap(Map<String, dynamic> map) {
    final pl = map['platforms'] as List<dynamic>?;
    return Version(
      id: map['id'] as String,
      projectId: map['projectId'] as String?,
      versionName: map['versionName'] as String?,
      platforms: pl == null ? null : List<String>.from(pl),
      downloadURL: map['downloadURL'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Version.fromJson(String source) =>
      Version.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Version(id: $id, projectId: $projectId, versionName: $versionName, platforms: $platforms, downloadURL: $downloadURL, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Version other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.projectId == projectId &&
        other.versionName == versionName &&
        // mapEquals(other.platforms, platforms) &&
        other.downloadURL == downloadURL &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        projectId.hashCode ^
        versionName.hashCode ^
        platforms.hashCode ^
        downloadURL.hashCode ^
        createdAt.hashCode;
  }
}
