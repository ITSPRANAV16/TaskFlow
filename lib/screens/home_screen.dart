import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_edit_task_sheet.dart';
import '../widgets/category_selector.dart';
import '../widgets/stats_header.dart';
import '../widgets/about_sheet.dart';
import '../services/update_service.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTaskSheet([TaskItem? task]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTaskSheet(taskToEdit: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 720;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search tasks...',
                  border: InputBorder.none,
                ),
                onChanged: (query) => provider.setSearchQuery(query),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: AppTheme.primaryViolet,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('TaskFlow'),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  provider.setSearchQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              provider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => provider.toggleThemeMode(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About Developer',
            onPressed: () => AboutSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Desktop Side Navigation / Summary Sidebar
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatsHeader(),
                      const SizedBox(height: 24),
                      Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: TaskCategory.values.length,
                          itemBuilder: (context, index) {
                            final category = TaskCategory.values[index];
                            final isSelected = provider.selectedCategory == category;
                            final color = AppTheme.getCategoryColor(category);
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: Icon(
                                _getCategoryIcon(category),
                                color: color,
                                size: 20,
                              ),
                              title: Text(
                                category.label,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              onTap: () => provider.setSelectedCategory(category),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Area for Desktop
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        _buildFilterTabs(provider, isDark),
                        const SizedBox(height: 16),
                        Expanded(child: _buildTaskList(provider, isDark)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const StatsHeader(),
                  const SizedBox(height: 16),
                  const CategorySelector(),
                  const SizedBox(height: 12),
                  _buildFilterTabs(provider, isDark),
                  const SizedBox(height: 12),
                  Expanded(child: _buildTaskList(provider, isDark)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTaskSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(TaskProvider provider, bool isDark) {
    final tabs = [
      {'id': 'all', 'label': 'All'},
      {'id': 'today', 'label': 'Today'},
      {'id': 'upcoming', 'label': 'Upcoming'},
      {'id': 'urgent', 'label': 'Urgent'},
      {'id': 'completed', 'label': 'Completed'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = provider.selectedFilterTab == tab['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(
                tab['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ),
              selectedColor: AppTheme.primaryViolet,
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryViolet
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              onSelected: (_) {
                provider.setFilterTab(tab['id']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskList(TaskProvider provider, bool isDark) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tasks = provider.filteredTasks;

    if (tasks.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 56,
                  color: AppTheme.primaryViolet,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Tasks Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "+ New Task" to create your first task!',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _openAddTaskSheet(),
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onTap: () => _openAddTaskSheet(task),
        );
      },
    );
  }

  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.all:
        return Icons.grid_view_rounded;
      case TaskCategory.work:
        return Icons.work_rounded;
      case TaskCategory.personal:
        return Icons.person_rounded;
      case TaskCategory.study:
        return Icons.menu_book_rounded;
      case TaskCategory.health:
        return Icons.favorite_rounded;
      case TaskCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TaskCategory.finance:
        return Icons.account_balance_wallet_rounded;
      case TaskCategory.other:
        return Icons.label_rounded;
    }
  }
}
