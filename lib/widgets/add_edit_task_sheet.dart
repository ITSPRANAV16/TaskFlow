import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class AddEditTaskSheet extends StatefulWidget {
  final TaskItem? taskToEdit;

  const AddEditTaskSheet({super.key, this.taskToEdit});

  @override
  State<AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends State<AddEditTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subtaskController;

  late DateTime _selectedDueDate;
  late TimeOfDay _selectedTime;
  late TaskPriority _selectedPriority;
  late TaskCategory _selectedCategory;
  late List<Subtask> _subtasks;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _subtaskController = TextEditingController();

    _selectedDueDate = task?.dueDate ?? DateTime.now().add(const Duration(hours: 3));
    _selectedTime = TimeOfDay.fromDateTime(_selectedDueDate);
    _selectedPriority = task?.priority ?? TaskPriority.medium;
    _selectedCategory = task?.category ?? TaskCategory.personal;
    _subtasks = task != null ? List.from(task.subtasks) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDueDate = DateTime(
          _selectedDueDate.year,
          _selectedDueDate.month,
          _selectedDueDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _subtasks.add(Subtask(
          id: const Uuid().v4(),
          title: title,
          isCompleted: false,
        ));
        _subtaskController.clear();
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      const uuid = Uuid();

      final task = TaskItem(
        id: widget.taskToEdit?.id ?? uuid.v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: _selectedDueDate,
        priority: _selectedPriority,
        category: _selectedCategory,
        isCompleted: widget.taskToEdit?.isCompleted ?? false,
        subtasks: _subtasks,
        createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.taskToEdit == null) {
        provider.addTask(task);
      } else {
        provider.updateTask(task);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.taskToEdit != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Task' : 'New Task',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Task Title Input
              TextFormField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'What needs to be done?',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBg : AppTheme.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Task Description Input
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add additional details or notes...',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBg : AppTheme.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Priority Selector
              Text(
                'Priority Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  final color = AppTheme.getPriorityColor(priority);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedPriority = priority),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.2)
                                : (isDark ? AppTheme.darkBg : AppTheme.lightCard),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            priority.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Category Dropdown
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TaskCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                    items: TaskCategory.values
                        .where((c) => c != TaskCategory.all)
                        .map((category) {
                      final color = AppTheme.getCategoryColor(category);
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(category.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Due Date & Time Selector Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBg : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.primaryViolet),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDueDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBg : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 20, color: AppTheme.primaryTeal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Subtasks Checklist Section
              Text(
                'Subtasks / Checklist (${_subtasks.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtask list items
              ..._subtasks.asMap().entries.map((entry) {
                final idx = entry.key;
                final subtask = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: subtask.isCompleted,
                        onChanged: (val) {
                          setState(() {
                            _subtasks[idx] = subtask.copyWith(isCompleted: val ?? false);
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: TextStyle(
                            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                            color: subtask.isCompleted ? Colors.grey : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _subtasks.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),

              // Subtask Add Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add a subtask item...',
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? AppTheme.darkBg : AppTheme.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _saveTask,
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create Task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
