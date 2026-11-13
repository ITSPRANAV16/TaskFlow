import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../theme/app_theme.dart';

/// Displays a donut chart and category-wise horizontal bars for expense breakdown.
class ExpenseCategoryChart extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryBreakdown;
  final double totalSpent;

  const ExpenseCategoryChart({
    super.key,
    required this.categoryBreakdown,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (categoryBreakdown.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.donut_large_rounded,
                size: 18,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Donut Chart
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  data: categoryBreakdown,
                  totalSpent: totalSpent,
                  isDark: isDark,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            fmt.format(totalSpent),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category Bars
          ...categoryBreakdown.entries.map((entry) {
            final percent = totalSpent > 0 ? entry.value / totalSpent : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(entry.key.icon, color: entry.key.color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        fmt.format(entry.value),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppTheme.darkCard
                          : AppTheme.lightCard,
                      valueColor: AlwaysStoppedAnimation(entry.key.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Custom painter for the donut chart.
class _DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double totalSpent;
  final bool isDark;

  _DonutChartPainter({
    required this.data,
    required this.totalSpent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 22.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Background ring
    final bgPaint = Paint()
      ..color = isDark ? AppTheme.darkCard : AppTheme.lightCard
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (totalSpent <= 0 || data.isEmpty) return;

    double startAngle = -math.pi / 2; // Start from top
    const gapAngle = 0.04; // Small gap between segments

    for (final entry in data.entries) {
      final sweepAngle =
          (entry.value / totalSpent) * (2 * math.pi) - gapAngle;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = entry.key.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.totalSpent != totalSpent;
  }
}
