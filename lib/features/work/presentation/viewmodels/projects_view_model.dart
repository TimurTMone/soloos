import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';

class ProjectsViewModel extends ChangeNotifier {
  ProjectsViewModel({StorageService? storage})
      : _storage = storage ?? StorageService() {
    _loadProjects();
  }

  final StorageService _storage;
  List<Project> _projects = [];
  bool _loading = false;

  List<Project> get projects => _projects;
  bool get loading => _loading;

  bool get _useDb => SupabaseService.isAuthenticated;

  Future<void> _loadProjects() async {
    _loading = true;
    notifyListeners();

    try {
      if (_useDb) {
        final rows = await SupabaseService.getAll('projects', orderBy: 'created_at');
        final taskRows = await SupabaseService.getAll('tasks', orderBy: 'created_at', ascending: true);

        // Group tasks by project_id
        final tasksByProject = <String, List<Task>>{};
        for (final r in taskRows) {
          final pid = r['project_id'] as String?;
          if (pid != null) {
            tasksByProject.putIfAbsent(pid, () => []).add(Task.fromRow(r));
          }
        }

        _projects = rows
            .map((r) => Project.fromRow(r, tasks: tasksByProject[r['id']] ?? []))
            .toList();
      } else {
        _projects = _storage.getProjects();
      }
    } catch (e) {
      // Fallback to local on error
      _projects = _storage.getProjects();
    }

    _loading = false;
    notifyListeners();
  }

  void reload() => _loadProjects();

  Future<bool> addProject({required String name, String description = ''}) async {
    if (name.trim().isEmpty) return false;
    final p = Project(
      id: const Uuid().v4(),
      name: name.trim(),
      description: description.trim(),
    );

    if (_useDb) {
      final row = p.toRow();
      row['user_id'] = SupabaseService.userId;
      await SupabaseService.client.from('projects').insert(row);
    }

    // Also save locally as cache
    final projects = _storage.getProjects()..add(p);
    await _storage.saveProjects(projects);
    await _loadProjects();
    return true;
  }

  Future<void> deleteProject(int index) async {
    final project = _projects[index];
    if (_useDb) {
      await SupabaseService.delete('projects', project.id);
    }
    _projects.removeAt(index);
    await _storage.saveProjects(_projects);
    notifyListeners();
  }

  Future<void> saveProjects() async {
    await _storage.saveProjects(_projects);
    notifyListeners();
  }

  Future<void> addTask(Project project, {required String title, required String priority}) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title.trim(),
      priority: priority,
    );
    project.tasks.add(task);

    if (_useDb) {
      final row = task.toRow(project.id);
      row['user_id'] = SupabaseService.userId;
      await SupabaseService.client.from('tasks').insert(row);
    }

    await _saveAndNotify();
  }

  Future<void> toggleTask(Task task) async {
    final completing = !task.isDone;
    task.isDone = completing;
    if (completing) {
      GamificationEventBus.emit(
        GamificationEventType.taskCompleted,
        description: task.title,
      );
    }

    if (_useDb) {
      await SupabaseService.update('tasks', task.id, {'is_done': task.isDone});
    }

    await _saveAndNotify();
  }

  Future<void> deleteTask(Project project, Task task) async {
    project.tasks.remove(task);
    if (_useDb) {
      await SupabaseService.delete('tasks', task.id);
    }
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await _storage.saveProjects(_projects);
    notifyListeners();
  }
}
