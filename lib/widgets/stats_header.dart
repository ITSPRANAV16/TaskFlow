import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = provider.todayCompletionRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily Progress Banner Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF4F46E5), const Color(0xFF0D9488)]
                  : [const Color(0xFF6366F1), const Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryViolet.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Progress",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${(progress * 100).toInt()}% Completed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Stats Cards Row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                title: 'Total',
                count: provider.totalCount.toString(),
                icon: Icons.format_list_bulleted_rounded,
                color: AppTheme.primaryViolet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                context,
                title: 'Pending',
                count: provider.pendingCount.toString(),
                icon: Icons.hourglass_top_rounded,
                color: AppTheme.accentAmber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                context,
                title: 'Done',
                count: provider.completedCount.toString(),
                icon: Icons.task_alt_rounded,
                color: AppTheme.accentEmerald,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                context,
                title: 'Urgent',
                count: provider.urgentCount.toString(),
                icon: Icons.priority_high_rounded,
                color: AppTheme.accentRose,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
