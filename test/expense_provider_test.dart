import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/models/expense_model.dart';
import 'package:task_flow/providers/expense_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Expense Model Tests', () {
    test('JSON serialization and deserialization retains all fields', () {
      final now = DateTime(2026, 11, 9, 14, 30);
      final expense = Expense(
        id: 'exp-101',
        title: 'Mess Monthly Fee',
        amount: 3200.0,
        category: ExpenseCategory.mess,
        date: now,
        note: 'Advance paid for November',
      );

      final json = expense.toJson();
      final restored = Expense.fromJson(json);

      expect(restored.id, equals(expense.id));
      expect(restored.title, equals('Mess Monthly Fee'));
      expect(restored.amount, equals(3200.0));
      expect(restored.category, equals(ExpenseCategory.mess));
      expect(restored.date, equals(now));
      expect(restored.note, equals('Advance paid for November'));
    });

    test('copyWith updates specified fields correctly', () {
      final original = Expense(
        id: 'exp-102',
        title: 'Snacks',
        amount: 80.0,
        category: ExpenseCategory.food,
        date: DateTime.now(),
      );

      final updated = original.copyWith(
        title: 'Canteen Lunch',
        amount: 150.0,
      );

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Canteen Lunch'));
      expect(updated.amount, equals(150.0));
      expect(updated.category, equals(ExpenseCategory.food));
    });
  });

  group('ExpenseProvider Budget & Savings Calculations', () {
    test('Budget setting, remaining budget, and savings work as expected', () async {
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setMonthlyBudget(5000.0);
      expect(provider.monthlyBudget, equals(5000.0));
      expect(provider.remainingBudget, equals(5000.0));
      expect(provider.savingsAmount, equals(5000.0));
      expect(provider.isOverBudget, isFalse);

      final now = DateTime.now();

      // Add expense 1
      provider.addExpense(Expense(
        id: 'e1',
        title: 'Stationery & Xerox',
        amount: 500.0,
        category: ExpenseCategory.stationery,
        date: now,
      ));

      // Add expense 2
      provider.addExpense(Expense(
        id: 'e2',
        title: 'Mess Dinner',
        amount: 1500.0,
        category: ExpenseCategory.mess,
        date: now,
      ));

      expect(provider.totalSpentThisMonth, equals(2000.0));
      expect(provider.totalSpentToday, equals(2000.0));
      expect(provider.remainingBudget, equals(3000.0));
      expect(provider.savingsAmount, equals(3000.0));
      expect(provider.budgetUsagePercent, closeTo(0.4, 0.01));
      expect(provider.isOverBudget, isFalse);

      // Add large expense that exceeds remaining budget
      provider.addExpense(Expense(
        id: 'e3',
        title: 'College Books',
        amount: 3500.0,
        category: ExpenseCategory.stationery,
        date: now,
      ));

      expect(provider.totalSpentThisMonth, equals(5500.0));
      expect(provider.remainingBudget, equals(-500.0));
      expect(provider.savingsAmount, equals(0.0)); // Savings floor is 0
      expect(provider.isOverBudget, isTrue);
      expect(provider.budgetUsagePercent, equals(1.0)); // Clamped to 1.0
    });

    test('Category breakdown aggregates amounts and sorts descending', () async {
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now();

      provider.addExpense(Expense(
        id: 'c1',
        title: 'Bus Pass',
        amount: 400.0,
        category: ExpenseCategory.transport,
        date: now,
      ));

      provider.addExpense(Expense(
        id: 'c2',
        title: 'Mess Extra',
        amount: 1200.0,
        category: ExpenseCategory.mess,
        date: now,
      ));

      provider.addExpense(Expense(
        id: 'c3',
        title: 'Juice',
        amount: 100.0,
        category: ExpenseCategory.food,
        date: now,
      ));

      provider.addExpense(Expense(
        id: 'c4',
        title: 'Lunch',
        amount: 250.0,
        category: ExpenseCategory.food,
        date: now,
      ));

      final breakdown = provider.categoryBreakdown;
      final keys = breakdown.keys.toList();

      // Mess: 1200, Food: 350 (100+250), Transport: 400 -> Sort: Mess (1200), Transport (400), Food (350)
      expect(keys.first, equals(ExpenseCategory.mess));
      expect(breakdown[ExpenseCategory.mess], equals(1200.0));
      expect(breakdown[ExpenseCategory.food], equals(350.0));
      expect(breakdown[ExpenseCategory.transport], equals(400.0));
    });

    test('Month navigation filters expenses correctly', () async {
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 10);
      final lastMonthDate = DateTime(now.year, now.month - 1, 15);

      provider.addExpense(Expense(
        id: 'cur-1',
        title: 'Current Month Expense',
        amount: 200.0,
        category: ExpenseCategory.food,
        date: currentMonthDate,
      ));

      provider.addExpense(Expense(
        id: 'prev-1',
        title: 'Previous Month Expense',
        amount: 600.0,
        category: ExpenseCategory.personal,
        date: lastMonthDate,
      ));

      // Currently on current month
      expect(provider.currentMonthExpenses.length, equals(1));
      expect(provider.currentMonthExpenses.first.id, equals('cur-1'));

      // Navigate to previous month
      provider.goToPreviousMonth();
      expect(provider.currentMonthExpenses.length, equals(1));
      expect(provider.currentMonthExpenses.first.id, equals('prev-1'));

      // Can navigate forward back to current month
      expect(provider.canGoToNextMonth, isTrue);
      provider.goToNextMonth();
      expect(provider.currentMonthExpenses.first.id, equals('cur-1'));

      // Cannot navigate to future month past current
      expect(provider.canGoToNextMonth, isFalse);
    });

    test('CRUD operations (update and delete) work properly', () async {
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final expense = Expense(
        id: 'crud-1',
        title: 'Notebook',
        amount: 60.0,
        category: ExpenseCategory.stationery,
        date: DateTime.now(),
      );

      provider.addExpense(expense);
      expect(provider.allExpenses.length, equals(1));

      // Update
      provider.updateExpense(expense.copyWith(amount: 75.0, title: 'Notebook & Pen'));
      expect(provider.allExpenses.first.amount, equals(75.0));
      expect(provider.allExpenses.first.title, equals('Notebook & Pen'));

      // Delete
      provider.deleteExpense('crud-1');
      expect(provider.allExpenses.isEmpty, isTrue);
    });

    test('Roommate splitting and balances calculate correctly', () async {
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now();

      // Case 1: You paid ₹300 for 3 roommates (You, Rohan, Aryan)
      // Your share: 100. Rohan owes: 100. Aryan owes: 100.
      provider.addExpense(Expense(
        id: 'split-1',
        title: 'Late Night Pizza',
        amount: 300.0,
        category: ExpenseCategory.food,
        date: now,
        isShared: true,
        paidBy: 'You',
        splitWith: const ['You', 'Rohan', 'Aryan'],
      ));

      expect(provider.totalOwedToMe, equals(200.0));
      expect(provider.totalIOweOthers, equals(0.0));
      expect(provider.personalTotalSpentThisMonth, equals(100.0));

      // Case 2: Aryan paid ₹400 for 2 roommates (You, Aryan)
      // Your share: 200. You owe Aryan: 200.
      provider.addExpense(Expense(
        id: 'split-2',
        title: 'Room Wi-Fi Recharge',
        amount: 400.0,
        category: ExpenseCategory.recharge,
        date: now,
        isShared: true,
        paidBy: 'Aryan',
        splitWith: const ['You', 'Aryan'],
      ));

      expect(provider.totalOwedToMe, equals(200.0));
      expect(provider.totalIOweOthers, equals(200.0));

      final balances = provider.roommateBalances;
      // Rohan owes you 100
      expect(balances['Rohan'], equals(100.0));
      // Aryan: Aryan owed you 100 from pizza, but you owe Aryan 200 from Wi-Fi -> Net: -100 (you owe Aryan 100)
      expect(balances['Aryan'], equals(-100.0));
    });

    test('Daily safe allowance and spending pace engine work', () async {
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setMonthlyBudget(6000.0);
      expect(provider.dailySafeSpendAllowance, greaterThan(0.0));
      expect(provider.daysRemainingInSelectedMonth, greaterThan(0));
      expect(provider.spendingPaceStatus, equals('healthy'));
    });
  });
}

