import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: TaskCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = TaskCategory.values[index];
          final isSelected = provider.selectedCategory == category;
          final categoryColor = AppTheme.getCategoryColor(category);

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            ),
            avatar: Icon(
              _getIconForCategory(category),
              size: 16,
              color: isSelected ? Colors.white : categoryColor,
            ),
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            selectedColor: categoryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? categoryColor
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                width: 1.2,
              ),
            ),
            onSelected: (_) {
              provider.setSelectedCategory(category);
            },
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(TaskCategory category) {
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
