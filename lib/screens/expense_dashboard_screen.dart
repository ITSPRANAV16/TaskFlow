import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_edit_expense_sheet.dart';
import '../widgets/expense_category_chart.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/expense_summary_cards.dart';
import '../widgets/set_budget_dialog.dart';
import '../widgets/daily_pace_card.dart';
import '../widgets/roommate_split_card.dart';
import '../widgets/export_report_sheet.dart';

class ExpenseDashboardScreen extends StatelessWidget {
  const ExpenseDashboardScreen({super.key});

  void _openAddExpenseSheet(BuildContext context, [Expense? expense]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<ExpenseProvider>(context, listen: false),
        child: AddEditExpenseSheet(expenseToEdit: expense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppTheme.primaryTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('SpendMate'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<TaskProvider>().isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => context.read<TaskProvider>().toggleThemeMode(),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Report',
            onPressed: () => ExportReportSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.savings_rounded),
            tooltip: 'Set Budget',
            onPressed: () => SetBudgetDialog.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            color: AppTheme.primaryTeal,
            onRefresh: () async {
              // Could refresh data here if backed by a server
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Month Selector ──
                  _MonthSelector(provider: provider, isDark: isDark),
                  const SizedBox(height: 16),

                  // ── Summary Cards ──
                  ExpenseSummaryCards(
                    monthlyBudget: provider.monthlyBudget,
                    totalSpent: provider.totalSpentThisMonth,
                    remaining: provider.remainingBudget,
                    todaySpent: provider.totalSpentToday,
                    isOverBudget: provider.isOverBudget,
                    onSetBudget: () => SetBudgetDialog.show(context),
                  ),
                  const SizedBox(height: 12),

                  // ── Daily Spend Pace Alert ──
                  if (provider.monthlyBudget > 0) ...[
                    DailyPaceCard(
                      safeDailyAllowance: provider.dailySafeSpendAllowance,
                      averageDailySpend: provider.averageDailySpend,
                      daysRemaining: provider.daysRemainingInSelectedMonth,
                      paceStatus: provider.spendingPaceStatus,
                      monthlyBudget: provider.monthlyBudget,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Roommate Split Ledger ──
                  if (provider.roommateBalances.isNotEmpty ||
                      provider.totalOwedToMe > 0 ||
                      provider.totalIOweOthers > 0) ...[
                    RoommateSplitCard(
                      roommateBalances: provider.roommateBalances,
                      totalOwedToMe: provider.totalOwedToMe,
                      totalIOweOthers: provider.totalIOweOthers,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Budget Progress Bar ──
                  if (provider.monthlyBudget > 0) ...[
                    _BudgetProgressBar(provider: provider, isDark: isDark),
                    const SizedBox(height: 16),
                  ],

                  // ── Quick Stats Row ──
                  _QuickStatsRow(provider: provider, isDark: isDark),
                  const SizedBox(height: 16),

                  // ── Category Breakdown Chart ──
                  ExpenseCategoryChart(
                    categoryBreakdown: provider.categoryBreakdown,
                    totalSpent: provider.totalSpentThisMonth,
                  ),
                  const SizedBox(height: 16),

                  // ── Daily Spending Bars ──
                  if (provider.currentMonthExpenses.isNotEmpty) ...[
                    _DailySpendingBars(provider: provider, isDark: isDark),
                    const SizedBox(height: 16),
                  ],

                  // ── Expenses List ──
                  _ExpensesList(
                    provider: provider,
                    isDark: isDark,
                    onTap: (expense) => _openAddExpenseSheet(context, expense),
                    onDelete: (id) {
                      provider.deleteExpense(id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense deleted')),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // FAB clearance
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddExpenseSheet(context),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// ── Private Sub-Widgets ──
// ─────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final ExpenseProvider provider;
  final bool isDark;

  const _MonthSelector({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => provider.goToPreviousMonth(),
            iconSize: 22,
          ),
          Text(
            monthFormat.format(provider.selectedMonth),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: provider.canGoToNextMonth
                  ? null
                  : (isDark ? AppTheme.darkCard : const Color(0xFFE2E8F0)),
            ),
            onPressed: provider.canGoToNextMonth
                ? () => provider.goToNextMonth()
                : null,
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressBar extends StatelessWidget {
  final ExpenseProvider provider;
  final bool isDark;

  const _BudgetProgressBar({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final percent = provider.budgetUsagePercent;
    final isOver = provider.isOverBudget;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Usage',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOver ? AppTheme.accentRose : AppTheme.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              valueColor: AlwaysStoppedAnimation(
                isOver
                    ? AppTheme.accentRose
                    : percent > 0.8
                        ? AppTheme.accentAmber
                        : AppTheme.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final ExpenseProvider provider;
  final bool isDark;

  const _QuickStatsRow({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Row(
      children: [
        _QuickStat(
          icon: Icons.receipt_long_rounded,
          label: 'Transactions',
          value: provider.currentMonthExpenseCount.toString(),
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _QuickStat(
          icon: Icons.trending_up_rounded,
          label: 'Avg/Day',
          value: fmt.format(provider.averageDailySpend),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySpendingBars extends StatelessWidget {
  final ExpenseProvider provider;
  final bool isDark;

  const _DailySpendingBars({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dailyMap = provider.dailySpendingMap;
    if (dailyMap.isEmpty) return const SizedBox.shrink();

    final maxAmount = dailyMap.values.reduce((a, b) => a > b ? a : b);
    final sortedDays = dailyMap.keys.toList()..sort();
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Spending',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sortedDays.map((day) {
                  final amount = dailyMap[day]!;
                  final barHeight = maxAmount > 0
                      ? (amount / maxAmount) * 100
                      : 0.0;
                  final now = DateTime.now();
                  final isToday = day == now.day &&
                      provider.selectedMonth.month == now.month &&
                      provider.selectedMonth.year == now.year;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          fmt.format(amount),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: barHeight.clamp(8.0, 100.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)]
                                  : [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday
                                ? AppTheme.primaryTeal
                                : (isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary),
                          ),
                        ),
                      ],
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
}

class _ExpensesList extends StatelessWidget {
  final ExpenseProvider provider;
  final bool isDark;
  final void Function(Expense) onTap;
  final void Function(String) onDelete;

  const _ExpensesList({
    required this.provider,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = provider.expensesGroupedByDate;
    final dateFormat = DateFormat('EEEE, dd MMM');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (grouped.isEmpty) {
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Expenses This Month',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "+ Add Expense" to start tracking!',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 18,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Expenses',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...grouped.entries.map((entry) {
          String dateLabel;
          if (entry.key.isAtSameMomentAs(today)) {
            dateLabel = 'Today';
          } else if (entry.key.isAtSameMomentAs(yesterday)) {
            dateLabel = 'Yesterday';
          } else {
            dateLabel = dateFormat.format(entry.key);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
              ...entry.value.map((expense) => ExpenseListTile(
                    expense: expense,
                    onTap: () => onTap(expense),
                    onDelete: () => onDelete(expense.id),
                  )),
            ],
          );
        }),
      ],
    );
  }
}
