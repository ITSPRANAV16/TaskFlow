import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskFlow App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TaskFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('TaskFlow'), findsOneWidget);
  });
}
