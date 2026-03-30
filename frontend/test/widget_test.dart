import 'package:flutter_test/flutter_test.dart';
import 'package:veto/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const VetoApp());
    await tester.pump();
    expect(find.byType(VetoApp), findsOneWidget);
  });
}
