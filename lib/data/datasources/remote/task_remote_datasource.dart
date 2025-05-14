import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/task_model.dart';
import '../../../config/app_config.dart';
import '../../../core/errors/exceptions.dart';

abstract class TaskRemoteDataSource {
  Future<List<Task>> getTasks();
  Future<Task> getTaskById(String id);
  Future<Task> addTask(Task task); // Return the created/updated task from server
  Future<Task> updateTask(Task task); // Return the updated task
  Future<void> deleteTask(String id);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final http.Client client;
  final String baseUrl = AppConfig.mockApiBaseUrl; // Or your actual base URL

  // Mock in-memory store for the "remote" server
  final Map<String, Task> _mockDb = {};

  TaskRemoteDataSourceImpl({required this.client});

  Uri _getUri(String path) => Uri.parse('$baseUrl/$path');

  Future<T> _handleRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(dynamic json) onSuccess,
  ) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      final response = await requestFunction();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) { // For DELETE requests that might return no body
          return onSuccess(null);
        }
        final jsonResponse = json.decode(response.body);
        return onSuccess(jsonResponse);
      } else if (response.statusCode == 404) {
        throw ServerException('Resource not found (404)');
      } else if (response.statusCode == 401) {
        throw ServerException('Unauthorized (401)');
      } else {
        throw ServerException(
            'Server error: ${response.statusCode} - ${response.body}');
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      // This catches http client errors (e.g., no connection if not handled by NetworkInfo)
      // or JSON parsing errors
      throw ServerException('Failed to communicate with server: ${e.toString()}');
    }
  }

  @override
  Future<List<Task>> getTasks() async {
    // MOCK IMPLEMENTATION
    return _handleRequest(
      () async {
        // Simulate GET /tasks
        print('REMOTE: Fetching all tasks');
        final tasksList = _mockDb.values.toList();
        return http.Response(json.encode(tasksList.map((t) => t.toJson()).toList()), 200);
      },
      (json) => (json as List).map((taskJson) => Task.fromJson(taskJson)).toList(),
    );
  }

  @override
  Future<Task> getTaskById(String id) async {
    // MOCK IMPLEMENTATION
    return _handleRequest(
      () async {
        // Simulate GET /tasks/:id
        print('REMOTE: Fetching task $id');
        if (_mockDb.containsKey(id)) {
          return http.Response(json.encode(_mockDb[id]!.toJson()), 200);
        } else {
          return http.Response('Not Found', 404);
        }
      },
      (json) => Task.fromJson(json),
    );
  }

  @override
  Future<Task> addTask(Task task) async {
    // MOCK IMPLEMENTATION
    return _handleRequest(
      () async {
        // Simulate POST /tasks
        print('REMOTE: Adding task ${task.title}');
        final newTask = task.copyWith(id: task.id); // Ensure ID is consistent if provided, or server generates
        _mockDb[newTask.id] = newTask;
        return http.Response(json.encode(newTask.toJson()), 201); // 201 Created
      },
      (json) => Task.fromJson(json),
    );
  }

  @override
  Future<Task> updateTask(Task task) async {
    // MOCK IMPLEMENTATION
    return _handleRequest(
      () async {
        // Simulate PUT /tasks/:id
        print('REMOTE: Updating task ${task.id}');
        if (_mockDb.containsKey(task.id)) {
          _mockDb[task.id] = task;
          return http.Response(json.encode(task.toJson()), 200);
        } else {
          return http.Response('Not Found', 404);
        }
      },
      (json) => Task.fromJson(json),
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    // MOCK IMPLEMENTATION
    // Note: _handleRequest expects a JSON response, so we adapt for void.
    // In a real API, a DELETE might return 204 No Content or 200 OK with a message.
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      print('REMOTE: Deleting task $id');
      if (_mockDb.containsKey(id)) {
        _mockDb.remove(id);
        // Simulate a 204 No Content or 200 OK
        // http.Response('', 204) or http.Response('{"message":"success"}', 200)
        // For _handleRequest to work without changes, we can return a dummy success
        // return http.Response('{"status":"deleted"}', 200);
        // Or, we modify how we call it or handle void return types better.
        // For simplicity, let's assume it succeeds if no error is thrown.
        return; // Directly return if it's a mock success
      } else {
        throw ServerException('Resource not found (404)');
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to delete task on server: ${e.toString()}');
    }
  }
}

/*
// Example of how you would use it with a real API:
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final http.Client client;
  final String baseUrl = AppConfig.apiBaseUrl;

  TaskRemoteDataSourceImpl({required this.client});

  Uri _getUri(String path) => Uri.parse('$baseUrl/$path');
  final Map<String, String> _headers = {'Content-Type': 'application/json'};


  Future<T> _handleRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(dynamic json) onSuccess,
  ) async {
    // ... same error handling as above ...
  }


  @override
  Future<List<Task>> getTasks() async {
    return _handleRequest(
      () => client.get(_getUri('tasks'), headers: _headers),
      (json) => (json as List).map((taskJson) => Task.fromJson(taskJson)).toList(),
    );
  }

  @override
  Future<Task> addTask(Task task) async {
    return _handleRequest(
      () => client.post(
        _getUri('tasks'),
        headers: _headers,
        body: json.encode(task.toJson()), // Send task without ID, server generates
      ),
      (json) => Task.fromJson(json),
    );
  }
  // ... other methods similarly ...
}
*/