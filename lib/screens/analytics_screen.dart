import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryBreakdown = provider.categoryBreakdown;
    final totalSpent = provider.totalSpentThisMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'खर्च विश्लेषण (Analytics)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
                    'या महिन्यासाठी कोणताही खर्च उपलब्ध नाही',
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
                  _buildMonthSummaryCard(provider, isDark),
                  const SizedBox(height: 18),

                  // 2. Category Pie / Donut Chart
                  _buildPieChartCard(categoryBreakdown, totalSpent, isDark),
                  const SizedBox(height: 18),

                  // 3. Category Breakdown List
                  _buildCategoryList(categoryBreakdown, totalSpent, isDark),
                  const SizedBox(height: 18),

                  // 4. Financial Health Card
                  _buildFinancialHealthCard(provider, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSummaryCard(ExpenseProvider provider, bool isDark) {
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
                  '${provider.currentMonthExpenseCount} व्यवहार',
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
                child: _buildStatItem(
                  'एकूण खर्च',
                  '₹${provider.totalSpentThisMonth.toStringAsFixed(0)}',
                  const Color(0xFFEF4444),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'दैनंदिन सरासरी',
                  '₹${provider.averageDailySpend.toStringAsFixed(0)}/दिवस',
                  const Color(0xFFF59E0B),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'सुरक्षित दैनंदिन',
                  '₹${provider.dailySafeSpendAllowance.toStringAsFixed(0)}/दिवस',
                  const Color(0xFF10B981),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(
    Map<ExpenseCategory, double> breakdown,
    double totalSpent,
    bool isDark,
  ) {
    if (breakdown.isEmpty || totalSpent <= 0) return const SizedBox.shrink();

    final entries = breakdown.entries.toList();

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
          const Text(
            'वर्गवारीनुसार विभागणी (Category Breakdown)',
            style: TextStyle(
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

  Widget _buildCategoryList(
    Map<ExpenseCategory, double> breakdown,
    double totalSpent,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'खर्चाचा तपशील',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...breakdown.entries.map((entry) {
          final percent = (entry.value / totalSpent) * 100;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: entry.key.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    entry.key.icon,
                    color: entry.key.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (percent / 100).clamp(0.0, 1.0),
                          backgroundColor:
                              isDark ? Colors.white12 : Colors.black12,
                          color: entry.key.color,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFinancialHealthCard(ExpenseProvider provider, bool isDark) {
    final status = provider.spendingPaceStatus;
    Color statusColor;
    String statusTitle;
    String statusDesc;

    switch (status) {
      case 'healthy':
        statusColor = const Color(0xFF10B981);
        statusTitle = 'आर्थिक आरोग्य: उत्तम ✅ (Healthy)';
        statusDesc =
            'आपला दैनंदिन खर्च बजेटच्या सुरक्षित मर्यादेत आहे. महिन्याअखेर बचत शक्य होईल.';
        break;
      case 'warning':
        statusColor = const Color(0xFFF59E0B);
        statusTitle = 'आर्थिक आरोग्य: मध्यम ⚠️ (Warning)';
        statusDesc =
            'आपण सुरक्षित मर्यादेपेक्षा जास्त वेगाने खर्च करत आहात. अनावश्यक खर्च टाळा.';
        break;
      case 'critical':
      default:
        statusColor = const Color(0xFFEF4444);
        statusTitle = 'आर्थिक आरोग्य: धोक्याची पातळी 🚨 (Critical)';
        statusDesc =
            'मासिक बजेट संपले आहे किंवा संपण्याच्या मार्गावर आहे. त्वरित बचत सुरू करा!';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusDesc,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

