import 'package:flutter_test/flutter_test.dart';

import 'package:profiminspectionapp/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProfimInspectionApp());

    // Since your app is not the default counter app, the rest of this test is no longer valid.
    // You can comment it out or write new tests once UI is ready.

    expect(find.text('Inspections'), findsOneWidget);
    // Add more valid tests when your app is ready.
  });
}
