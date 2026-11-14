import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/models/settlement.dart';
import 'package:task_flow/providers/locale_provider.dart';
import 'package:task_flow/services/upi_service.dart';
import 'package:task_flow/utils/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Settlement Model Tests', () {
    test('Settlement serialization and deserialization', () {
      final now = DateTime.now();
      final settlement = Settlement(
        id: 'set-101',
        roommateName: 'Kunal',
        amount: 450.0,
        date: now,
        paymentMethod: 'UPI',
        note: 'Mess bill share',
      );

      final json = settlement.toJson();
      expect(json['id'], 'set-101');
      expect(json['roommateName'], 'Kunal');
      expect(json['amount'], 450.0);
      expect(json['paymentMethod'], 'UPI');

      final reconstructed = Settlement.fromJson(json);
      expect(reconstructed.id, 'set-101');
      expect(reconstructed.roommateName, 'Kunal');
      expect(reconstructed.amount, 450.0);
      expect(reconstructed.paymentMethod, 'UPI');
    });
  });

  group('UpiService Format Tests', () {
    test('Formats 10-digit phone number with default handle', () {
      final vpa = UpiService.formatVpa('9876543210', handle: '@okaxis');
      expect(vpa, '9876543210@okaxis');
    });

    test('Leaves already fully-formed UPI ID intact', () {
      final vpa = UpiService.formatVpa('user@paytm', handle: '@ybl');
      expect(vpa, 'user@paytm');
    });

    test('Strips +91 from phone number', () {
      final vpa = UpiService.formatVpa('+919876543210', handle: '@upi');
      expect(vpa, '9876543210@upi');
    });
  });

  group('AppStrings & LocaleProvider Tests', () {
    test('Default language returns English string', () {
      expect(AppStrings.get('app_name'), 'SpendMate');
      expect(AppStrings.get('nav_expenses'), 'Expenses');
    });

    test('Marathi flag returns Marathi string', () {
      expect(AppStrings.get('app_name', isMarathi: true), 'SpendMate');
      expect(AppStrings.get('nav_expenses', isMarathi: true), 'खर्च');
    });

    test('LocaleProvider default is English', () async {
      final provider = LocaleProvider();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.isMarathi, false);
      expect(provider.tr('nav_expenses'), 'Expenses');
    });

    test('LocaleProvider toggles to Marathi', () async {
      final provider = LocaleProvider();
      await provider.setLanguage(AppLanguage.marathi);
      expect(provider.isMarathi, true);
      expect(provider.tr('nav_expenses'), 'खर्च');
    });
  });
}

