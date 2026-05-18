import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api/tasks';
  static const String _localTasksKey = 'local_tasks_backup';
  
  // ValueNotifier to let the UI know if we are in Offline (Local Storage) mode
  final ValueNotifier<bool> isOfflineNotifier = ValueNotifier<bool>(false);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Check backend server availability
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        isOfflineNotifier.value = false;
        return true;
      }
    } catch (_) {}
    isOfflineNotifier.value = true;
    return false;
  }

  // Helper: Load backup tasks from Local Storage
  Future<List<TaskModel>> _loadLocalTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_localTasksKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonStr);
        return list.map((item) => TaskModel.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading local tasks: $e');
    }
    return [];
  }

  // Helper: Save tasks to Local Storage as offline backup
  Future<void> _saveLocalTasks(List<TaskModel> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = json.encode(tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_localTasksKey, jsonStr);
    } catch (e) {
      if (kDebugMode) print('Error saving local tasks: $e');
    }
  }

  // 1. Get all tasks
  Future<List<TaskModel>> getTasks() async {
    final bool isOnline = await checkServerHealth();
    
    if (isOnline) {
      try {
        final response = await http.get(Uri.parse(baseUrl));
        if (response.statusCode == 200) {
          final List<dynamic> body = json.decode(response.body);
          final tasks = body.map((item) => TaskModel.fromJson(item)).toList();
          
          // Save a backup copy in local storage
          await _saveLocalTasks(tasks);
          return tasks;
        }
      } catch (e) {
        if (kDebugMode) print('Failed to fetch online tasks: $e');
      }
    }
    
    // Fallback to local storage
    isOfflineNotifier.value = true;
    return await _loadLocalTasks();
  }

  // 2. Create task
  Future<TaskModel> createTask(TaskModel task) async {
    final bool isOnline = await checkServerHealth();
    
    if (isOnline) {
      try {
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(task.toJson()),
        );
        if (response.statusCode == 201) {
          final createdTask = TaskModel.fromJson(json.decode(response.body));
          
          // Sync offline list
          final localTasks = await _loadLocalTasks();
          localTasks.insert(0, createdTask);
          await _saveLocalTasks(localTasks);
          
          return createdTask;
        }
      } catch (e) {
        if (kDebugMode) print('Failed to create online task: $e');
      }
    }
    
    // Offline implementation: Create a local task with random ID
    isOfflineNotifier.value = true;
    final offlineTask = task.copyWith(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
    );
    final localTasks = await _loadLocalTasks();
    localTasks.insert(0, offlineTask);
    await _saveLocalTasks(localTasks);
    return offlineTask;
  }

  // 3. Update task
  Future<TaskModel> updateTask(TaskModel task) async {
    if (task.id == null) return task;
    
    final bool isOnline = await checkServerHealth();
    
    // Check if it's a locally created task that hasn't been uploaded to MongoDB yet
    final isLocalOnly = task.id!.startsWith('local_');

    if (isOnline && !isLocalOnly) {
      try {
        final response = await http.put(
          Uri.parse('$baseUrl/${task.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(task.toJson()),
        );
        if (response.statusCode == 200) {
          final updatedTask = TaskModel.fromJson(json.decode(response.body));
          
          // Sync offline list
          final localTasks = await _loadLocalTasks();
          final index = localTasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            localTasks[index] = updatedTask;
            await _saveLocalTasks(localTasks);
          }
          
          return updatedTask;
        }
      } catch (e) {
        if (kDebugMode) print('Failed to update online task: $e');
      }
    }
    
    // Offline implementation (or local task update)
    isOfflineNotifier.value = true;
    final localTasks = await _loadLocalTasks();
    final index = localTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      localTasks[index] = task;
      await _saveLocalTasks(localTasks);
    }
    return task;
  }

  // 4. Delete task
  Future<bool> deleteTask(String id) async {
    final bool isOnline = await checkServerHealth();
    final isLocalOnly = id.startsWith('local_');
    
    bool deleteSuccess = false;

    if (isOnline && !isLocalOnly) {
      try {
        final response = await http.delete(Uri.parse('$baseUrl/$id'));
        if (response.statusCode == 200) {
          deleteSuccess = true;
        }
      } catch (e) {
        if (kDebugMode) print('Failed to delete online task: $e');
      }
    } else if (isLocalOnly) {
      // If it was local only, we just delete it locally
      deleteSuccess = true;
    }
    
    // Sync offline list (always remove locally)
    final localTasks = await _loadLocalTasks();
    localTasks.removeWhere((t) => t.id == id);
    await _saveLocalTasks(localTasks);
    
    if (!isOnline) {
      isOfflineNotifier.value = true;
      deleteSuccess = true; // Pretend it succeeded offline
    }
    
    return deleteSuccess;
  }

  // Sync offline-only tasks to server once server comes back online
  Future<void> syncOfflineTasksToServer() async {
    if (await checkServerHealth() == false) return;
    
    final localTasks = await _loadLocalTasks();
    final localOnlyTasks = localTasks.where((t) => t.id != null && t.id!.startsWith('local_')).toList();
    
    if (localOnlyTasks.isEmpty) return;

    for (var task in localOnlyTasks) {
      try {
        // Create clean task without ID for MongoDB to generate its own ID
        final cleanTask = TaskModel(
          title: task.title,
          description: task.description,
          category: task.category,
          dueDate: task.dueDate,
          priority: task.priority,
          status: task.status,
          isCompleted: task.isCompleted,
        );
        
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(cleanTask.toJson()),
        );
        
        if (response.statusCode == 201) {
          final uploaded = TaskModel.fromJson(json.decode(response.body));
          // Remove local-only version and add server-provided version
          final idx = localTasks.indexWhere((t) => t.id == task.id);
          if (idx != -1) {
            localTasks[idx] = uploaded;
          }
        }
      } catch (_) {
        break; // Stop syncing if connection breaks midway
      }
    }
    await _saveLocalTasks(localTasks);
  }
}
