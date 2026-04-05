import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:veto/core/i18n/app_language.dart';
import 'package:veto/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppLanguageController(),
        child: const VetoApp(),
      ),
    );

    await tester.pump();

    expect(find.text('VETO'), findsOneWidget);
  });
}
