import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/providers/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskFlow App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TaskProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: Text('TaskFlow'),
          ),
        ),
      ),
    );

    expect(find.text('TaskFlow'), findsOneWidget);
  });
}
