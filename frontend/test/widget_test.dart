import 'package:flutter_test/flutter_test.dart';
import 'package:veto/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const VetoApp());
    // Splash screen uses a 2-second delay before routing.
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(VetoApp), findsOneWidget);
  });
}
