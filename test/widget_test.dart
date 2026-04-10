import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigator/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusNavigatorApp());
    expect(find.byType(CampusNavigatorApp), findsOneWidget);
  });
}