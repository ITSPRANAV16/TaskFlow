import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/models/expense_model.dart';
import 'package:task_flow/services/cloud_sync_service.dart';
import 'package:task_flow/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default state has no PIN and app lock disabled', () async {
      final security = SecurityService();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(security.isAppLockEnabled, false);
      expect(security.hasPin, false);
    });

    test('Setting 4-digit PIN hashes and verifies correctly', () async {
      final security = SecurityService();
      await Future.delayed(const Duration(milliseconds: 50));

      final setSuccess = await security.setPin('1234');
      expect(setSuccess, true);
      expect(security.hasPin, true);

      // Correct PIN unlocks
      expect(security.verifyPin('1234'), true);
      expect(security.isAuthenticated, true);

      // Incorrect PIN fails
      expect(security.verifyPin('0000'), false);
    });

    test('App lock toggle works properly', () async {
      final security = SecurityService();
      await Future.delayed(const Duration(milliseconds: 50));

      await security.setAppLockEnabled(true);
      expect(security.isAppLockEnabled, true);

      security.lockApp();
      expect(security.isAuthenticated, false);

      security.unlock();
      expect(security.isAuthenticated, true);
    });
  });

  group('CloudSyncService (Zero Data Loss) Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Two-way merge combines disjoint local and cloud expenses without losing any', () {
      final sync = CloudSyncService();

      final localExp = [
        Expense(
          id: 'exp_1',
          title: 'Hostel Mess',
          amount: 2500,
          category: ExpenseCategory.mess,
          date: DateTime(2026, 11, 1),
        ),
      ];

      final cloudExp = [
        Expense(
          id: 'exp_2',
          title: 'Books',
          amount: 600,
          category: ExpenseCategory.stationery,
          date: DateTime(2026, 11, 2),
        ),
      ];

      final merged = sync.mergeExpenses(localExp, cloudExp);

      expect(merged.length, 2);
      expect(merged.any((e) => e.id == 'exp_1'), true);
      expect(merged.any((e) => e.id == 'exp_2'), true);
    });

    test('Two-way merge resolves overlapping UUID with newer modification without deleting', () {
      final sync = CloudSyncService();

      final olderCloud = Expense(
        id: 'exp_10',
        title: 'Snacks Old',
        amount: 100,
        category: ExpenseCategory.food,
        date: DateTime(2026, 11, 5),
        createdAt: DateTime(2026, 11, 5, 10, 0),
      );

      final newerLocal = Expense(
        id: 'exp_10',
        title: 'Snacks Updated',
        amount: 150,
        category: ExpenseCategory.food,
        date: DateTime(2026, 11, 5),
        createdAt: DateTime(2026, 11, 5, 12, 0),
      );

      final merged = sync.mergeExpenses([newerLocal], [olderCloud]);

      expect(merged.length, 1);
      expect(merged.first.id, 'exp_10');
      expect(merged.first.title, 'Snacks Updated');
      expect(merged.first.amount, 150);
    });
  });
}

