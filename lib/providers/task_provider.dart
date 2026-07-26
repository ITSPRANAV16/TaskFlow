import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  static const String _storageKey = 'taskflow_tasks_v1';
  static const String _themeStorageKey = 'taskflow_theme_mode';

  final List<TaskItem> _tasks = [];
  TaskCategory _selectedCategory = TaskCategory.all;
  String _selectedFilterTab = 'all'; // 'all', 'today', 'upcoming', 'urgent', 'completed'
  String _searchQuery = '';
  bool _isDarkMode = true;
  bool _isLoading = true;

  List<TaskItem> get allTasks => List.unmodifiable(_tasks);
  TaskCategory get selectedCategory => _selectedCategory;
  String get selectedFilterTab => _selectedFilterTab;
  String get searchQuery => _searchQuery;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeStorageKey) ?? true;
    
    final tasksJsonString = prefs.getString(_storageKey);
    if (tasksJsonString != null && tasksJsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(tasksJsonString);
        _tasks.clear();
        for (var item in decoded) {
          _tasks.add(TaskItem.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading tasks: $e');
        _loadSeedData();
      }
    } else {
      _loadSeedData();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _loadSeedData() {
    _tasks.clear();
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  void toggleThemeMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeStorageKey, _isDarkMode);
  }

  void setSelectedCategory(TaskCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setFilterTab(String filter) {
    _selectedFilterTab = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Filtered Tasks list calculation
  List<TaskItem> get filteredTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _tasks.where((task) {
      // Category filter
      if (_selectedCategory != TaskCategory.all && task.category != _selectedCategory) {
        return false;
      }

      // Search Query filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDesc = task.description.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc) return false;
      }

      // Filter Tab
      switch (_selectedFilterTab) {
        case 'today':
          final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          return taskDate.isAtSameMomentAs(today);
        case 'upcoming':
          final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          return taskDate.isAfter(today) && !task.isCompleted;
        case 'urgent':
          return (task.priority == TaskPriority.urgent || task.priority == TaskPriority.high) && !task.isCompleted;
        case 'completed':
          return task.isCompleted;
        case 'all':
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) {
        // Uncompleted first, then by priority rank descending, then due date
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        if (a.priority != b.priority) {
          return b.priority.rank.compareTo(a.priority.rank);
        }
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  // Statistics
  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get urgentCount => _tasks.where((t) => (t.priority == TaskPriority.urgent || t.priority == TaskPriority.high) && !t.isCompleted).length;

  double get todayCompletionRate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTasks = _tasks.where((t) {
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return taskDate.isAtSameMomentAs(today);
    }).toList();

    if (todayTasks.isEmpty) return 0.0;
    final completed = todayTasks.where((t) => t.isCompleted).length;
    return completed / todayTasks.length;
  }

  // CRUD Operations
  void addTask(TaskItem task) {
    _tasks.insert(0, task);
    _saveToPrefs();
    notifyListeners();
  }

  void updateTask(TaskItem updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveToPrefs();
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newStatus = !task.isCompleted;
      
      // If toggling main task completion, update subtasks too if desired
      final updatedSubtasks = task.subtasks.map((s) => s.copyWith(isCompleted: newStatus)).toList();

      _tasks[index] = task.copyWith(
        isCompleted: newStatus,
        subtasks: updatedSubtasks,
      );
      _saveToPrefs();
      notifyListeners();
    }
  }

  void toggleSubtaskCompletion(String taskId, String subtaskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedSubtasks = task.subtasks.map((s) {
        if (s.id == subtaskId) {
          return s.copyWith(isCompleted: !s.isCompleted);
        }
        return s;
      }).toList();

      // Check if all subtasks are completed
      final allSubtasksDone = updatedSubtasks.isNotEmpty && updatedSubtasks.every((s) => s.isCompleted);

      _tasks[index] = task.copyWith(
        subtasks: updatedSubtasks,
        isCompleted: allSubtasksDone ? true : task.isCompleted,
      );
      _saveToPrefs();
      notifyListeners();
    }
  }
}
