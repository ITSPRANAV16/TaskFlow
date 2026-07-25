import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = AppTheme.getPriorityColor(task.priority);
    final categoryColor = AppTheme.getCategoryColor(task.category);

    final dateFormat = DateFormat('MMM dd, hh:mm a');
    final formattedDate = dateFormat.format(task.dueDate);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.accentRose,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        provider.deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" deleted'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppTheme.primaryTeal,
              onPressed: () {
                provider.addTask(task);
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: task.isCompleted
                  ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
            boxShadow: task.isCompleted
                ? []
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category Badge + Checkbox + Priority Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Completion Checkbox
                  Transform.scale(
                    scale: 1.15,
                    child: Checkbox(
                      value: task.isCompleted,
                      activeColor: AppTheme.accentEmerald,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (_) {
                        provider.toggleTaskCompletion(task.id);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Title and Category
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted
                            ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                            : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: priorityColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      task.priority.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Task Description
              if (task.description.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 4, bottom: 8),
                  child: Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Bottom Info Bar: Due Date + Subtasks progress + Category chip
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Category Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.category.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Due Date
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task.isOverdue
                              ? Icons.error_outline_rounded
                              : Icons.calendar_today_rounded,
                          size: 13,
                          color: task.isOverdue
                              ? AppTheme.accentRose
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                            color: task.isOverdue
                                ? AppTheme.accentRose
                                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),

                    // Subtask Count Badge
                    if (task.subtasks.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
