import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../models/settlement.dart';
import '../services/notification_service.dart';
import '../services/persistent_backup_service.dart';

class ExpenseProvider with ChangeNotifier {
  static const String _storageKey = 'taskflow_expenses_v1';
  static const String _budgetKey = 'taskflow_monthly_budget';
  static const String _settlementsKey = 'spendmate_settlements_v1';

  final List<Expense> _expenses = [];
  final List<Settlement> _settlements = [];
  double _monthlyBudget = 0.0;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;

  // ── Public Getters ──

  List<Expense> get allExpenses => List.unmodifiable(_expenses);
  List<Settlement> get settlements => List.unmodifiable(_settlements);
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

    final settlementsJson = prefs.getString(_settlementsKey);
    if (settlementsJson != null && settlementsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(settlementsJson);
        _settlements.clear();
        for (var item in decoded) {
          _settlements.add(Settlement.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading settlements: $e');
      }
    }
    // If local expenses are empty (e.g. fresh installation or reinstall),
    // automatically search persistent device mirrors to restore all user transactions!
    if (_expenses.isEmpty) {
      try {
        final restored =
            await PersistentBackupService.restorePersistentBackup();
        if (restored != null && restored.expenses.isNotEmpty) {
          _expenses.clear();
          _expenses.addAll(restored.expenses);
          if (restored.settlements.isNotEmpty) {
            _settlements.clear();
            _settlements.addAll(restored.settlements);
          }
          if (restored.monthlyBudget != null && restored.monthlyBudget! > 0) {
            _monthlyBudget = restored.monthlyBudget!;
          }
          await _saveExpenses();
          await _saveSettlements();
          await _saveBudget();
          debugPrint(
              'Auto-Restored ${restored.expenses.length} expenses from ${restored.source}!');
        }
      } catch (e) {
        debugPrint('Error auto-restoring persistent backup: $e');
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

      // Auto-mirror to persistent storage so data survives uninstallation
      PersistentBackupService.savePersistentBackup(
        expenses: _expenses,
        settlements: _settlements,
        monthlyBudget: _monthlyBudget,
      );
    } catch (e) {
      debugPrint('Error saving expenses: $e');
    }
  }

  Future<void> _saveSettlements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(_settlements.map((s) => s.toJson()).toList());
      await prefs.setString(_settlementsKey, encoded);

      PersistentBackupService.savePersistentBackup(
        expenses: _expenses,
        settlements: _settlements,
        monthlyBudget: _monthlyBudget,
      );
    } catch (e) {
      debugPrint('Error saving settlements: $e');
    }
  }

  Future<void> _saveBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_budgetKey, _monthlyBudget);

      PersistentBackupService.savePersistentBackup(
        expenses: _expenses,
        settlements: _settlements,
        monthlyBudget: _monthlyBudget,
      );
    } catch (e) {
      debugPrint('Error saving budget: $e');
    }
  }

  /// Manually triggers a restore from persistent mirrors or cloud for the user.
  Future<int> restoreFromPersistentBackup({String? email}) async {
    final restored =
        await PersistentBackupService.restorePersistentBackup(filterEmail: email);
    if (restored != null && restored.expenses.isNotEmpty) {
      final Map<String, Expense> map = {};
      for (final exp in _expenses) {
        map[exp.id] = exp;
      }
      for (final exp in restored.expenses) {
        if (!map.containsKey(exp.id)) {
          map[exp.id] = exp;
        } else {
          final existing = map[exp.id]!;
          if (exp.createdAt.isAfter(existing.createdAt)) {
            map[exp.id] = exp;
          }
        }
      }
      _expenses.clear();
      _expenses.addAll(map.values.toList()..sort((a, b) => b.date.compareTo(a.date)));

      if (restored.settlements.isNotEmpty) {
        _settlements.clear();
        _settlements.addAll(restored.settlements);
      }
      if (restored.monthlyBudget != null && restored.monthlyBudget! > 0) {
        _monthlyBudget = restored.monthlyBudget!;
      }
      await _saveExpenses();
      await _saveSettlements();
      await _saveBudget();
      notifyListeners();
      return _expenses.length;
    }
    return 0;
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

  List<Settlement> get currentMonthSettlements {
    return _settlements.where((s) {
      return s.date.year == _selectedMonth.year &&
          s.date.month == _selectedMonth.month;
    }).toList();
  }

  /// Total money roommates owe you for shared bills you paid upfront.
  double get totalOwedToMe {
    return currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amountOthersOweMe);
  }

  /// Total money you owe roommates for shared bills they paid upfront.
  double get totalIOweOthers {
    return currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amountIOweOthers);
  }

  /// Net balance per roommate (+ means they owe you, - means you owe them, adjusted by settlements).
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

    // Adjust by settlements recorded in the selected period
    for (final s in currentMonthSettlements) {
      final name = s.roommateName.trim();
      if (!balances.containsKey(name)) {
        balances[name] = 0.0;
      }
      final currentBal = balances[name] ?? 0.0;
      if (currentBal > 0) {
        balances[name] = (currentBal - s.amount);
      } else if (currentBal < 0) {
        balances[name] = (currentBal + s.amount);
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

    // Trigger instant system notification
    NotificationService().notifyExpenseAdded(
      expense,
      isOverBudget: isOverBudget,
      budgetUsagePercent: budgetUsagePercent,
    );
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

  /// Update expense list with merged results from cloud (Zero Data Loss)
  void setMergedExpenses(List<Expense> mergedList) {
    _expenses.clear();
    _expenses.addAll(mergedList);
    _saveExpenses();
    notifyListeners();
  }

  /// Record a roommate settlement with persistence
  void recordSettlement(
    String roommate,
    double amount, {
    String paymentMethod = 'UPI',
    String note = '',
  }) {
    final settlement = Settlement(
      id: const Uuid().v4(),
      roommateName: roommate,
      amount: amount,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
      note: note,
    );
    _settlements.insert(0, settlement);
    _saveSettlements();
    notifyListeners();

    NotificationService().notifySettlement(roommate, amount);
  }

  /// Undo or delete a settlement
  void deleteSettlement(String settlementId) {
    _settlements.removeWhere((s) => s.id == settlementId);
    _saveSettlements();
    notifyListeners();
  }

  /// Clear all expenses and settlements (Safe Wipe)
  void clearAllData() {
    _expenses.clear();
    _settlements.clear();
    _monthlyBudget = 0.0;
    _saveExpenses();
    _saveSettlements();
    _saveBudget();
    notifyListeners();
  }
}
