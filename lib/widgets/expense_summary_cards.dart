import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseSummaryCards extends StatelessWidget {
  final double monthlyBudget;
  final double totalSpent;
  final double remaining;
  final double todaySpent;
  final bool isOverBudget;
  final VoidCallback? onSetBudget;

  const ExpenseSummaryCards({
    super.key,
    required this.monthlyBudget,
    required this.totalSpent,
    required this.remaining,
    required this.todaySpent,
    required this.isOverBudget,
    this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (monthlyBudget <= 0) {
      return _buildNoBudgetCard(context, isDark);
    }

    return Column(
      children: [
        // Top row: Budget + Spent
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Budget',
                value: fmt.format(monthlyBudget),
                icon: Icons.account_balance_wallet_rounded,
                gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Spent',
                value: fmt.format(totalSpent),
                icon: Icons.shopping_cart_rounded,
                gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Bottom row: Saved/Remaining + Today
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: isOverBudget ? 'Over Budget' : 'Saved',
                value: isOverBudget
                    ? '-${fmt.format((totalSpent - monthlyBudget).abs())}'
                    : fmt.format(remaining),
                icon: isOverBudget ? Icons.warning_rounded : Icons.savings_rounded,
                gradient: isOverBudget
                    ? const [Color(0xFFF43F5E), Color(0xFFFB7185)]
                    : const [Color(0xFF10B981), Color(0xFF34D399)],
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Today',
                value: fmt.format(todaySpent),
                icon: Icons.today_rounded,
                gradient: const [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoBudgetCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: onSetBudget,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.savings_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Monthly Budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to set your budget and start tracking savings!',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final bool isDark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
