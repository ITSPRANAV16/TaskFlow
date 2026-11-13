import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class DailyPaceCard extends StatelessWidget {
  final double safeDailyAllowance;
  final double averageDailySpend;
  final int daysRemaining;
  final String paceStatus; // 'healthy', 'warning', 'critical', 'neutral'
  final double monthlyBudget;

  const DailyPaceCard({
    super.key,
    required this.safeDailyAllowance,
    required this.averageDailySpend,
    required this.daysRemaining,
    required this.paceStatus,
    required this.monthlyBudget,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyBudget <= 0 || daysRemaining <= 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    switch (paceStatus) {
      case 'healthy':
        statusColor = const Color(0xFF10B981); // Emerald
        statusIcon = Icons.check_circle_outline_rounded;
        statusTitle = 'Pace: On Track';
        statusSubtitle = 'Average ₹${averageDailySpend.toStringAsFixed(0)}/day vs. safe ₹${safeDailyAllowance.toStringAsFixed(0)}/day';
        break;
      case 'warning':
        statusColor = const Color(0xFFF59E0B); // Amber
        statusIcon = Icons.warning_amber_rounded;
        statusTitle = 'Pace: Caution';
        statusSubtitle = 'Approaching safe limit (safe: ₹${safeDailyAllowance.toStringAsFixed(0)}/day)';
        break;
      case 'critical':
        statusColor = const Color(0xFFF43F5E); // Rose
        statusIcon = Icons.error_outline_rounded;
        statusTitle = 'Pace: Spending Fast';
        statusSubtitle = 'Current spending pace exceeds safe daily allocation';
        break;
      default:
        statusColor = AppTheme.primaryTeal;
        statusIcon = Icons.info_outline_rounded;
        statusTitle = 'Daily Allowance';
        statusSubtitle = '₹${safeDailyAllowance.toStringAsFixed(0)}/day safe spend';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$daysRemaining days left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Safe Daily Spend: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    Text(
                      fmt.format(safeDailyAllowance),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const Text(' /day', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

