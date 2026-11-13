import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  static const String _storageKey = 'taskflow_expenses_v1';
  static const String _budgetKey = 'taskflow_monthly_budget';

  final List<Expense> _expenses = [];
  double _monthlyBudget = 0.0;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;

  // ── Public Getters ──

  List<Expense> get allExpenses => List.unmodifiable(_expenses);
  double get monthlyBudget => _monthlyBudget;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;

  ExpenseProvider() {
    _init();
  }

  // ── Initialization & Persistence ──

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlyBudget = prefs.getDouble(_budgetKey) ?? 0.0;

    final expensesJson = prefs.getString(_storageKey);
    if (expensesJson != null && expensesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(expensesJson);
        _expenses.clear();
        for (var item in decoded) {
          _expenses.add(Expense.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading expenses: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(_expenses.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving expenses: $e');
    }
  }

  Future<void> _saveBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_budgetKey, _monthlyBudget);
    } catch (e) {
      debugPrint('Error saving budget: $e');
    }
  }

  // ── Month Navigation ──

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  void goToPreviousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  void goToNextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    // Don't allow navigating past current month
    if (!next.isAfter(DateTime(now.year, now.month))) {
      _selectedMonth = next;
      notifyListeners();
    }
  }

  bool get canGoToNextMonth {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return !next.isAfter(DateTime(now.year, now.month));
  }

  // ── Filtered Expense Lists ──

  List<Expense> get currentMonthExpenses {
    return _expenses
        .where((e) =>
            e.date.year == _selectedMonth.year &&
            e.date.month == _selectedMonth.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> get todayExpenses {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _expenses.where((e) {
      final expDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expDate.isAtSameMomentAs(today);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Groups current month expenses by date (descending).
  Map<DateTime, List<Expense>> get expensesGroupedByDate {
    final grouped = <DateTime, List<Expense>>{};
    for (final expense in currentMonthExpenses) {
      final dateKey =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }
    // Sort each group by createdAt descending
    for (final list in grouped.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  // ── Budget & Savings Statistics ──

  double get totalSpentThisMonth {
    return currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalSpentToday {
    return todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get remainingBudget {
    if (_monthlyBudget <= 0) return 0.0;
    return _monthlyBudget - totalSpentThisMonth;
  }

  double get savingsAmount {
    if (_monthlyBudget <= 0) return 0.0;
    final remaining = _monthlyBudget - totalSpentThisMonth;
    return remaining > 0 ? remaining : 0.0;
  }

  double get budgetUsagePercent {
    if (_monthlyBudget <= 0) return 0.0;
    return (totalSpentThisMonth / _monthlyBudget).clamp(0.0, 1.0);
  }

  bool get isOverBudget {
    return _monthlyBudget > 0 && totalSpentThisMonth > _monthlyBudget;
  }

  /// Category-wise spending for the selected month, sorted by amount descending.
  Map<ExpenseCategory, double> get categoryBreakdown {
    final breakdown = <ExpenseCategory, double>{};
    for (final expense in currentMonthExpenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0.0) + expense.amount;
    }
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Daily spending totals for the selected month (day number → amount).
  Map<int, double> get dailySpendingMap {
    final map = <int, double>{};
    for (final expense in currentMonthExpenses) {
      map[expense.date.day] =
          (map[expense.date.day] ?? 0.0) + expense.amount;
    }
    return map;
  }

  double get averageDailySpend {
    final expenses = currentMonthExpenses;
    if (expenses.isEmpty) return 0.0;
    final uniqueDays = expenses
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();
    return totalSpentThisMonth / uniqueDays.length;
  }

  int get currentMonthExpenseCount => currentMonthExpenses.length;

  // ── Hostel & Roommate Split Tracking ──

  /// Personal share of spending for the selected month (excludes portions owed by others).
  double get personalTotalSpentThisMonth {
    return currentMonthExpenses.fold(0.0, (sum, e) => sum + e.myShare);
  }

  /// Total money roommates owe you for shared bills you paid upfront.
  double get totalOwedToMe {
    return currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amountOthersOweMe);
  }

  /// Total money you owe roommates for shared bills they paid upfront.
  double get totalIOweOthers {
    return currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amountIOweOthers);
  }

  /// Net balance per roommate (+ means they owe you, - means you owe them).
  Map<String, double> get roommateBalances {
    final balances = <String, double>{};
    for (final expense in currentMonthExpenses) {
      if (!expense.isShared) continue;

      if (expense.didIPay) {
        // You paid: all other members owe you their share
        for (final member in expense.splitWith) {
          final trimmed = member.trim();
          final lower = trimmed.toLowerCase();
          if (lower == 'you' || lower == 'self' || lower == 'me') continue;
          balances[trimmed] =
              (balances[trimmed] ?? 0.0) + expense.sharePerPerson;
        }
      } else {
        // Someone else paid: you owe that person your share
        final payer = expense.paidBy.trim();
        balances[payer] = (balances[payer] ?? 0.0) - expense.sharePerPerson;
      }
    }
    return balances;
  }

  List<Expense> get sharedExpenses =>
      currentMonthExpenses.where((e) => e.isShared).toList();

  List<Expense> get recurringExpenses =>
      _expenses.where((e) => e.isRecurring).toList();

  // ── Smart Daily Spend Pace Engine ──

  int get daysRemainingInSelectedMonth {
    final now = DateTime.now();
    // If viewing past month
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      return 0;
    }
    final totalDaysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final currentDay = now.day;
    return (totalDaysInMonth - currentDay + 1).clamp(1, totalDaysInMonth);
  }

  /// Safe daily amount a student can spend to stay within budget.
  double get dailySafeSpendAllowance {
    final days = daysRemainingInSelectedMonth;
    if (_monthlyBudget <= 0 || remainingBudget <= 0 || days <= 0) return 0.0;
    return remainingBudget / days;
  }

  /// Budget spending velocity: 'healthy', 'warning', or 'critical'
  String get spendingPaceStatus {
    if (_monthlyBudget <= 0) return 'neutral';
    if (isOverBudget) return 'critical';
    final safeDaily = dailySafeSpendAllowance;
    final avgDaily = averageDailySpend;
    if (avgDaily <= safeDaily || avgDaily == 0) return 'healthy';
    if (avgDaily <= safeDaily * 1.25) return 'warning';
    return 'critical';
  }

  // ── CRUD Operations ──

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    _saveExpenses();
    notifyListeners();
  }

  void updateExpense(Expense updatedExpense) {
    final index = _expenses.indexWhere((e) => e.id == updatedExpense.id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      _saveExpenses();
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    _saveExpenses();
    notifyListeners();
  }

  void setMonthlyBudget(double budget) {
    _monthlyBudget = budget;
    _saveBudget();
    notifyListeners();
  }
}
