import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/models/expense_model.dart';
import 'package:task_flow/services/expense_export_service.dart';

void main() {
  group('ExpenseExportService Tests', () {
    final testMonth = DateTime(2026, 11, 1);
    final sampleExpenses = [
      Expense(
        id: 'e-1',
        title: 'Mess Fee',
        amount: 3000.0,
        category: ExpenseCategory.mess,
        date: DateTime(2026, 11, 2, 10, 0),
        isRecurring: true,
        note: 'Advance for Nov',
      ),
      Expense(
        id: 'e-2',
        title: 'Room Snacks, Drinks',
        amount: 300.0,
        category: ExpenseCategory.food,
        date: DateTime(2026, 11, 5, 21, 30),
        isShared: true,
        paidBy: 'You',
        splitWith: const ['You', 'Rohan', 'Aryan'],
      ),
    ];

    test('generateCsv outputs compliant CSV with header and records', () {
      final csv = ExpenseExportService.generateCsv(
        month: testMonth,
        expenses: sampleExpenses,
        monthlyBudget: 5000.0,
        totalSpent: 3300.0,
        remainingBudget: 1700.0,
      );

      expect(csv.contains('# Hostel Expense Report - November 2026'), isTrue);
      expect(csv.contains('# Monthly Budget: ₹5000.00'), isTrue);
      expect(csv.contains('Date,Time,Title,Category,Total Amount (INR),Your Share (INR),Is Shared,Paid By,Split With,Recurring,Note'), isTrue);
      expect(csv.contains('Mess Fee'), isTrue);
      expect(csv.contains('"Room Snacks, Drinks"'), isTrue); // Quotes escaped
      expect(csv.contains('3000.00'), isTrue);
    });

    test('generateParentSummaryText creates structured readable summary', () {
      final summary = ExpenseExportService.generateParentSummaryText(
        month: testMonth,
        expenses: sampleExpenses,
        monthlyBudget: 5000.0,
        totalSpent: 3300.0,
        remainingBudget: 1700.0,
        categoryBreakdown: {
          ExpenseCategory.mess: 3000.0,
          ExpenseCategory.food: 300.0,
        },
        roommateBalances: {
          'Rohan': 100.0,
          'Aryan': 100.0,
        },
      );

      expect(summary.contains('Hostel Expense Summary - November 2026'), isTrue);
      expect(summary.contains('Monthly Budget: ₹5,000'), isTrue);
      expect(summary.contains('Total Spent:    ₹3,300'), isTrue);
      expect(summary.contains('Money Saved:    ₹1,700'), isTrue);
      expect(summary.contains('Mess: ₹3,000'), isTrue);
      expect(summary.contains('Rohan owes you ₹100'), isTrue);
    });
  });
}

