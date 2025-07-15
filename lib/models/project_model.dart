import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class Project {
  final int id;
  final String name;
  final String description;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  Project copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Project.fromJson(String source) =>
      Project.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Project(id: $id, name: $name, description: $description, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Project other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        createdAt.hashCode;
  }
}
