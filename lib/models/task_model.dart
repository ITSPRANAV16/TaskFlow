enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  int get rank {
    switch (this) {
      case TaskPriority.urgent:
        return 4;
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }
}

enum TaskCategory { all, work, personal, study, health, shopping, finance, other }

extension TaskCategoryExtension on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.all:
        return 'All';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.shopping:
        return 'Shopping';
      case TaskCategory.finance:
        return 'Finance';
      case TaskCategory.other:
        return 'Other';
    }
  }
}

class Subtask {
  final String id;
  final String title;
  final bool isCompleted;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskCategory category;
  final bool isCompleted;
  final List<Subtask> subtasks;
  final DateTime createdAt;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
    this.isCompleted = false,
    this.subtasks = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get completionProgress {
    if (subtasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    return completedCount / subtasks.length;
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    return dueDate.isBefore(now);
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isCompleted,
    List<Subtask>? subtasks,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'category': category.name,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      category: TaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TaskCategory.personal,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => Subtask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
