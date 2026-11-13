import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/providers/expense_provider.dart';
import 'package:task_flow/providers/task_provider.dart';
import 'package:task_flow/screens/expense_dashboard_screen.dart';
import 'package:task_flow/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createDashboardTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ExpenseDashboardScreen(),
      ),
    );
  }

  testWidgets('ExpenseDashboardScreen renders with empty state and add expense button', (tester) async {
    await tester.pumpWidget(createDashboardTestWidget());
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('SpendMate'), findsOneWidget);

    // Verify Set Budget CTA card or button
    expect(find.text('Set Monthly Budget'), findsOneWidget);

    // Verify Empty state text
    expect(find.text('No Expenses This Month'), findsOneWidget);

    // Verify Floating Action Button
    expect(find.text('Add Expense'), findsOneWidget);
  });

  testWidgets('Tapping FAB opens AddEditExpenseSheet modal', (tester) async {
    await tester.pumpWidget(createDashboardTestWidget());
    await tester.pumpAndSettle();

    // Tap the FAB to open the add expense sheet
    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();

    // Verify the bottom sheet title and form fields are visible
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Mess'), findsOneWidget);
    expect(find.text('Stationery'), findsOneWidget);
  });
}

