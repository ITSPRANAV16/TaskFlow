import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskFlow App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TaskFlowApp());
    await tester.pump();

    expect(find.byType(TaskFlowApp), findsOneWidget);

    // Advance fake async timer by 5 seconds to complete SplashScreen timer
    await tester.pump(const Duration(seconds: 5));
  });
}
