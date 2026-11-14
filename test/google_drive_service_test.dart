import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/models/expense_model.dart';
import 'package:task_flow/services/google_drive_service.dart';

void main() {
  group('GoogleDriveService Two-Way Zero Data Loss Merge Tests', () {
    late GoogleDriveService driveService;

    setUp(() {
      driveService = GoogleDriveService();
    });

    test('Merges disjoint local and Google Drive remote expenses without loss', () {
      final local = [
        Expense(
          id: 'local_1',
          title: 'Grocery from Store',
          amount: 350.0,
          date: DateTime(2026, 11, 14, 10, 0),
          category: ExpenseCategory.food,
          paidBy: 'Pranav Patil',
          createdAt: DateTime(2026, 11, 14, 10, 0),
        ),
      ];

      final remote = [
        Expense(
          id: 'cloud_1',
          title: 'Wifi Bill Shared',
          amount: 800.0,
          date: DateTime(2026, 11, 13, 14, 0),
          category: ExpenseCategory.recharge,
          paidBy: 'Roommate',
          createdAt: DateTime(2026, 11, 13, 14, 0),
        ),
      ];

      final merged = driveService.mergeExpenses(local, remote);

      expect(merged.length, 2);
      expect(merged.any((e) => e.id == 'local_1'), isTrue);
      expect(merged.any((e) => e.id == 'cloud_1'), isTrue);
    });

    test('Resolves conflicting UUID by keeping the newer createdAt modification', () {
      final earlier = DateTime(2026, 11, 10, 10, 0);
      final later = DateTime(2026, 11, 10, 12, 0);

      final local = [
        Expense(
          id: 'same_id_1',
          title: 'Hostel Mess (Updated Locally)',
          amount: 5200.0,
          date: DateTime(2026, 11, 10),
          category: ExpenseCategory.mess,
          paidBy: 'Pranav Patil',
          createdAt: later, // Newer
        ),
      ];

      final remote = [
        Expense(
          id: 'same_id_1',
          title: 'Hostel Mess (Old on Cloud)',
          amount: 5000.0,
          date: DateTime(2026, 11, 10),
          category: ExpenseCategory.mess,
          paidBy: 'Pranav Patil',
          createdAt: earlier, // Older
        ),
      ];

      final merged = driveService.mergeExpenses(local, remote);

      expect(merged.length, 1);
      expect(merged.first.title, 'Hostel Mess (Updated Locally)');
      expect(merged.first.amount, 5200.0);
    });
  });
}
