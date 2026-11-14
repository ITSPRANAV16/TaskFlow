import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/expense_pdf_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final loc = context.watch<LocaleProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryBreakdown = provider.categoryBreakdown;
    final totalSpent = provider.totalSpentThisMonth;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('expense_analytics'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: loc.tr('export_pdf_report'),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: provider.currentMonthExpenses.isEmpty
                ? null
                : () => _exportPdf(context, provider),
          ),
        ],
      ),
      body: provider.currentMonthExpenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.tr('no_expenses'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Month Header & Quick Stats
                  _buildMonthSummaryCard(provider, loc, isDark),
                  const SizedBox(height: 18),

                  // 2. Category Pie / Donut Chart
                  _buildPieChartCard(categoryBreakdown, totalSpent, loc, isDark),
                  const SizedBox(height: 18),

                  // 3. Category Breakdown List
                  _buildCategoryList(categoryBreakdown, totalSpent, loc, isDark),
                  const SizedBox(height: 18),

                  // 4. Financial Health Card
                  _buildFinancialHealthCard(provider, loc, isDark),
                  const SizedBox(height: 18),

                  // 5. Download / Print PDF Card
                  _buildPdfExportCard(context, provider, loc, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _exportPdf(BuildContext context, ExpenseProvider provider) async {
    final auth = context.read<AuthService>();
    final userName = auth.currentUser?.name ?? 'SpendMate User';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF Financial Statement...'),
        duration: Duration(seconds: 1),
      ),
    );

    await ExpensePdfService.generateAndShareMonthlyReport(
      month: provider.selectedMonth,
      expenses: provider.currentMonthExpenses,
      settlements: provider.currentMonthSettlements,
      monthlyBudget: provider.monthlyBudget,
      totalSpent: provider.totalSpentThisMonth,
      personalShare: provider.personalTotalSpentThisMonth,
      categoryBreakdown: provider.categoryBreakdown
          .map((k, v) => MapEntry(k.label, v)),
      roommateBalances: provider.roommateBalances,
      userName: userName,
    );
  }

  Widget _buildPdfExportCard(BuildContext context, ExpenseProvider provider,
      LocaleProvider loc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFF6366F1),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('export_pdf_report'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Download or share monthly ledger statement',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _exportPdf(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummaryCard(
      ExpenseProvider provider, LocaleProvider loc, bool isDark) {
    final monthStr = DateFormat('MMMM yyyy').format(provider.selectedMonth);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.currentMonthExpenseCount} transactions',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: loc.tr('total_spent'),
                  value: '₹${provider.totalSpentThisMonth.toStringAsFixed(0)}',
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: loc.tr('monthly_budget'),
                  value: provider.monthlyBudget > 0
                      ? '₹${provider.monthlyBudget.toStringAsFixed(0)}'
                      : 'Not Set',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: loc.tr('remaining'),
                  value: provider.monthlyBudget > 0
                      ? '₹${provider.remainingBudget.toStringAsFixed(0)}'
                      : '—',
                  color: provider.isOverBudget
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF06B6D4),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(Map<ExpenseCategory, double> categoryBreakdown,
      double totalSpent, LocaleProvider loc, bool isDark) {
    if (categoryBreakdown.isEmpty || totalSpent == 0) {
      return const SizedBox.shrink();
    }

    final entries = categoryBreakdown.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.tr('category_breakdown'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 46,
                sections: entries.asMap().entries.map((item) {
                  final idx = item.key;
                  final entry = item.value;
                  final isTouched = idx == _touchedPieIndex;
                  final radius = isTouched ? 48.0 : 40.0;
                  final percent = (entry.value / totalSpent) * 100;

                  return PieChartSectionData(
                    color: entry.key.color,
                    value: entry.value,
                    title: percent >= 7 ? '${percent.toStringAsFixed(0)}%' : '',
                    radius: radius,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(Map<ExpenseCategory, double> categoryBreakdown,
      double totalSpent, LocaleProvider loc, bool isDark) {
    if (categoryBreakdown.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.tr('category_breakdown'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...categoryBreakdown.entries.map((entry) {
            final percent =
                totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
            final color = entry.key.color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
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
                      Expanded(
                        child: Text(
                          entry.key.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)} ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '(${percent.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      backgroundColor:
                          isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
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

  Widget _buildFinancialHealthCard(
      ExpenseProvider provider, LocaleProvider loc, bool isDark) {
    final status = provider.spendingPaceStatus;
    final dailyAllowance = provider.dailySafeSpendAllowance;
    final daysLeft = provider.daysRemainingInSelectedMonth;

    Color badgeColor;
    String statusTitle;
    String statusDesc;
    IconData statusIcon;

    switch (status) {
      case 'healthy':
        badgeColor = const Color(0xFF10B981);
        statusTitle = 'Safe Spending Pace';
        statusDesc =
            'You have ₹${dailyAllowance.toStringAsFixed(0)}/day safe limit for the remaining $daysLeft days.';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'warning':
        badgeColor = const Color(0xFFF59E0B);
        statusTitle = 'Caution: Spending Faster Than Planned';
        statusDesc =
            'Try to keep spending within ₹${dailyAllowance.toStringAsFixed(0)}/day.';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'critical':
        badgeColor = const Color(0xFFEF4444);
        statusTitle = 'Critical: Budget Exceeded';
        statusDesc =
            'You have spent more than your planned monthly limit. Avoid non-essential expenses.';
        statusIcon = Icons.error_outline_rounded;
        break;
      default:
        badgeColor = const Color(0xFF6366F1);
        statusTitle = 'No Budget Limit Set';
        statusDesc = 'Set a monthly budget to unlock spending pace insights.';
        statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: badgeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
