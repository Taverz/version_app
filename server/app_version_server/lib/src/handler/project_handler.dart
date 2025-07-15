import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:app_version_server/src/models/project_model.dart';
import 'package:shelf/shelf.dart';

import 'package:app_version_server/src/data/local/database_service.dart';
import 'package:uuid/uuid.dart' as uuid_import;

mixin ProjectHandler {
  Future<Response> getProject(Request request, String id) async {
    try {
      final projectId = int.tryParse(id);
      if (projectId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid project ID format'}),
        );
      }

      final value = DatabaseService().getProjectById(projectId);

      if ((value ?? {}).isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Project not found'}));
      }

      final project = Project.fromMap(value!);

      return Response.ok(
        jsonEncode(project.toMap()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      log('Error getting project: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get project'}),
      );
    }
  }

  Future<Response> updateProject(Request request, String id) async {
    try {
      final projectId = int.tryParse(id);
      if (projectId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid project ID format'}),
        );
      }

      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;

      if (updates.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'No update data provided'}),
        );
      }

      final allowedFields = {'name', 'description'};
      final filteredUpdates = Map.fromEntries(
        updates.entries.where((entry) => allowedFields.contains(entry.key)),
      );

      filteredUpdates['updatedAt'] = DateTime.now().toIso8601String();

      if (filteredUpdates.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'No valid fields to update'}),
        );
      }

      final resultSuccess = DatabaseService().updateProject(projectId, updates);

      if (!resultSuccess) {
        return Response.notFound(jsonEncode({'error': 'Project not updated'}));
      }

      return Response.ok(
        jsonEncode({'success': 'Project success updated'}),
        headers: {'Content-Type': 'application/json'},
      );
    } on FormatException {
      return Response.badRequest(
        body: jsonEncode({'error': 'Invalid JSON format'}),
      );
    } catch (e, stackTrace) {
      log('Error updating project: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update project'}),
      );
    }
  }

  Future<Response> getAllProjects(Request request) async {
    try {
      final value = DatabaseService().getAllProjects();

      return Response.ok(
        jsonEncode(value),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      log('Error getting projects: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get projects'}),
      );
    }
  }

  Future<Response> createProject(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['name'] == null || data['name'].toString().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Project name is required'}),
        );
      }
      final project = Project(
        id: uuid_import.Uuid().v4(),
        name: data['name'].toString(),
        description: data['description']?.toString() ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final valueSuccess = DatabaseService().createProject(project.toMap());

      return Response.ok(
        jsonEncode({"success": 'Project created', 'result': valueSuccess}),
        headers: {'Content-Type': 'application/json'},
      );
    } on FormatException {
      return Response.badRequest(
        body: jsonEncode({'error': 'Invalid JSON format'}),
      );
    } catch (e, stackTrace) {
      log('Error creating project: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create project'}),
      );
    }
  }

  Future<Response> deleteProject(Request request, String id) async {
    try {
      final idInt = int.tryParse(id);
      if (idInt == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid project ID'}),
        );
      }

      final successDelete = DatabaseService().deleteProject(idInt);

      if (!successDelete) {
        return Response.notFound(jsonEncode({'error': 'Project not deleted'}));
      }

      return Response.ok(
        jsonEncode({'status': 'deleted'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      log('Error deleting project: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete project'}),
      );
    }
  }
}
