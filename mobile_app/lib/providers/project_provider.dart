import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/api_service.dart';

/// Holds dashboard stats + the project list, and exposes the plan-gate logic.
class ProjectProvider extends ChangeNotifier {
  DashboardStats? stats;
  List<Project> projects = [];
  bool loading = false;
  String? error;

  /// PLAN GATE: true when the tenant has reached its project limit.
  /// A null maxProjects means "unlimited" (Enterprise) → never at the limit.
  bool get atProjectLimit {
    final s = stats;
    if (s == null || s.maxProjects == null) return false;
    return s.projectCount >= s.maxProjects!;
  }

  Future<void> loadDashboard() async {
    try {
      final res = await ApiService.instance.dio.get('/tenant/dashboard');
      stats = DashboardStats.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      error = apiError(e, 'Could not load the dashboard.');
    }
    notifyListeners();
  }

  Future<void> loadProjects() async {
    loading = true;
    notifyListeners();
    try {
      final res = await ApiService.instance.dio.get('/tenant/projects');
      projects = (res.data['data'] as List)
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      error = apiError(e, 'Could not load projects.');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Load dashboard + projects together (used when Home opens or on pull-to-refresh).
  Future<void> loadAll() async {
    await Future.wait([loadDashboard(), loadProjects()]);
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> createProject(String name, String description) async {
    try {
      await ApiService.instance.dio.post('/tenant/projects', data: {
        'name': name.trim(),
        if (description.trim().isNotEmpty) 'description': description.trim(),
      });
      await loadProjects();
      await loadDashboard(); // refresh counts so the plan gate stays accurate
      return null;
    } catch (e) {
      return apiError(e, 'Could not create project.');
    }
  }

  // --- Tasks (loaded per project by the detail screen) ---
  Future<List<Task>> loadTasks(int projectId) async {
    final res = await ApiService.instance.dio.get('/tenant/projects/$projectId/tasks');
    return (res.data['data'] as List)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> createTask(int projectId, String title, String status) async {
    try {
      await ApiService.instance.dio.post('/tenant/projects/$projectId/tasks', data: {
        'title': title.trim(),
        'status': status,
      });
      return null;
    } catch (e) {
      return apiError(e, 'Could not create task.');
    }
  }
}
