import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/models/task_model.dart';
import 'package:task_flow/providers/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskItem Model Tests', () {
    test('JSON Serialization & Deserialization works correctly', () {
      final now = DateTime.now();
      final task = TaskItem(
        id: 'test-id-1',
        title: 'Complete Flutter Task Manager',
        description: 'Test description',
        dueDate: now,
        priority: TaskPriority.urgent,
        category: TaskCategory.work,
        isCompleted: false,
        subtasks: [
          Subtask(id: 's1', title: 'Write Tests', isCompleted: true),
          Subtask(id: 's2', title: 'Verify Layout', isCompleted: false),
        ],
      );

      final json = task.toJson();
      final restored = TaskItem.fromJson(json);

      expect(restored.id, equals(task.id));
      expect(restored.title, equals(task.title));
      expect(restored.priority, equals(TaskPriority.urgent));
      expect(restored.category, equals(TaskCategory.work));
      expect(restored.subtasks.length, equals(2));
      expect(restored.subtasks.first.isCompleted, isTrue);
      expect(restored.completionProgress, equals(0.5));
    });
  });

  group('TaskProvider State Tests', () {
    test('Task addition and filtering works', () async {
      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final initialCount = provider.allTasks.length;
      final newTask = TaskItem(
        id: 'custom-id',
        title: 'New Custom Task',
        dueDate: DateTime.now(),
        priority: TaskPriority.high,
        category: TaskCategory.health,
      );

      provider.addTask(newTask);
      expect(provider.allTasks.length, equals(initialCount + 1));

      provider.setSelectedCategory(TaskCategory.health);
      final healthTasks = provider.filteredTasks;
      expect(healthTasks.any((t) => t.id == 'custom-id'), isTrue);
    });
  });
}
