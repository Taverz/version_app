import 'dart:convert';
import 'dart:io';

import 'package:app_version_server/src/models/version_model.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    _initDatabase();
  }

  Database get db {
    if (_database == null) {
      throw StateError('Database not initialized');
    }
    return _database!;
  }

  Future<Map<String, dynamic>?> getVersionById(String versionId) async {
    final stmt = db.prepare('SELECT * FROM versions WHERE id = ?');
    try {
      final result = stmt.select([versionId]);
      return result.isNotEmpty ? _rowToVersionMap(result.first) : null;
    } finally {
      stmt.dispose();
    }
  }

  Future<bool> deleteVersion(String versionId) async {
    final stmt = db.prepare('DELETE FROM versions WHERE id = ?');
    try {
      stmt.execute([versionId]);
      return true;
    } catch (e) {
      print('Error deleting version: $e');
      return false;
    } finally {
      stmt.dispose();
    }
  }

  Map<String, dynamic> _rowToVersionMap(Row row) {
    return {
      'id': row['id'],
      'projectId': row['projectId'],
      'versionName': row['versionName'],
      'platforms': jsonDecode(row['platforms'] as String),
      'downloadURL': row['downloadURL'],
      'createdAt': row['createdAt'],
    };
  }

  void _initDatabase() {
    final dbPath = join(Directory.current.path, 'app_database.db');
    _database = sqlite3.open(dbPath);
    _database!.execute('PRAGMA foreign_keys = ON');
    _createTables();
  }

  void _createTables() {
    db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS versions (
        id TEXT PRIMARY KEY,
        projectId INTEGER NOT NULL,
        versionName TEXT NOT NULL,
        platforms TEXT NOT NULL,
        downloadURL TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
  }

  List<Map<String, dynamic>> getAllProjects() {
    final result = db.select('SELECT * FROM projects ORDER BY createdAt DESC');
    return result.map((row) => _rowToMap(row)).toList();
  }

  Map<String, dynamic>? getProjectById(int id) {
    final stmt = db.prepare('SELECT * FROM projects WHERE id = ?');
    final result = stmt.select([id]);
    stmt.dispose();
    return result.isEmpty ? null : _rowToMap(result.first);
  }

  int createProject(Map<String, dynamic> project) {
    final stmt = db.prepare('''
      INSERT INTO projects (name, description, createdAt, updatedAt)
      VALUES (?, ?, ?, ?)
    ''');
    stmt.execute([
      project['name'],
      project['description'],
      DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
    ]);
    final id = db.lastInsertRowId;
    stmt.dispose();
    return id;
  }

  bool updateProject(int id, Map<String, dynamic> updates) {
    final validUpdates = {
      if (updates.containsKey('name')) 'name': updates['name'],
      if (updates.containsKey('description'))
        'description': updates['description'],
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (validUpdates.isEmpty) return false;

    final setClause = validUpdates.keys.map((k) => '$k = ?').join(', ');
    final values = [...validUpdates.values, id];

    final checkStmt = db.prepare('SELECT 1 FROM projects WHERE id = ?');
    try {
      final exists = checkStmt.select([id]).isNotEmpty;
      if (!exists) return false;
    } finally {
      checkStmt.dispose();
    }

    // 4. Выполнение обновления
    final updateStmt = db.prepare('''
    UPDATE projects 
    SET $setClause
    WHERE id = ?
  ''');
    try {
      updateStmt.execute(values);

      final verifyStmt = db.prepare('''
      SELECT 1 FROM projects 
      WHERE id = ? AND updatedAt = ?
    ''');
      try {
        return verifyStmt.select([id, validUpdates['updatedAt']]).isNotEmpty;
      } finally {
        verifyStmt.dispose();
      }
    } finally {
      updateStmt.dispose();
    }
  }

  bool deleteProject(int id) {
    final checkStmt = db.prepare('SELECT 1 FROM projects WHERE id = ?');
    try {
      final exists = checkStmt.select([id]).isNotEmpty;
      if (!exists) return false;
    } finally {
      checkStmt.dispose();
    }

    final deleteStmt = db.prepare('DELETE FROM projects WHERE id = ?');
    try {
      deleteStmt.execute([id]);

      final verifyStmt = db.prepare('SELECT 1 FROM projects WHERE id = ?');
      try {
        return !verifyStmt.select([id]).isNotEmpty;
      } finally {
        verifyStmt.dispose();
      }
    } finally {
      deleteStmt.dispose();
    }
  }

  List<Map<String, dynamic>> getVersionsByProjectId(int projectId) {
    final stmt = db.prepare('''
    SELECT * FROM versions 
    WHERE projectId = ?
    ORDER BY createdAt DESC
  ''');
    try {
      final result = stmt.select([projectId]);
      return result.map((row) {
        final map = _rowToVersionMap(row);
        map['platforms'] = jsonDecode(map['platforms'] as String);
        return map;
      }).toList();
    } finally {
      stmt.dispose();
    }
  }

  VersionApp? getLastVersionByProjectId(int projectId) {
    final stmt = db.prepare('''
    SELECT * FROM versions 
    WHERE projectId = ?
    ORDER BY createdAt DESC
    LIMIT 1
  ''');
    try {
      final result = stmt.select([projectId]);
      final resultValue = result.isEmpty
          ? null
          : _rowToVersionMap(result.first);
      return resultValue == null ? null : VersionApp.fromMap(resultValue);
    } finally {
      stmt.dispose();
    }
  }

  VersionApp? getVersionByProjectId(int projectId, String versionId) {
    final stmt = db.prepare('''
    SELECT * FROM versions 
    WHERE projectId = ? AND id = ?
    LIMIT 1
  ''');
    try {
      final result = stmt.select([projectId, versionId]);
      final resultValue = result.isEmpty 
          ? null 
          : _rowToVersionMap(result.first);
      return resultValue == null ? null : VersionApp.fromMap(resultValue);
    } finally {
      stmt.dispose();
    }
  }

  bool createVersion(Map<String, dynamic> version) {
    final stmt = db.prepare('''
      INSERT INTO versions 
      (id, projectId, versionName, platforms, downloadURL, createdAt)
      VALUES (?, ?, ?, ?, ?, ?)
    ''');
    try {
      stmt.execute([
        version['id'],
        version['projectId'],
        version['versionName'],
        jsonEncode(version['platforms']),
        version['downloadURL'],
        DateTime.now().toIso8601String(),
      ]);
      return true;
    } catch (e) {
      return false;
    } finally {
      stmt.dispose();
    }
  }

  Map<String, dynamic> _rowToMap(Row row) {
    return {
      'id': row['id'],
      'name': row['name'],
      'description': row['description'],
      'createdAt': row['createdAt'],
      'updatedAt': row['updatedAt'],
    };
  }

  void close() {
    _database?.dispose();
    _database = null;
  }
}
