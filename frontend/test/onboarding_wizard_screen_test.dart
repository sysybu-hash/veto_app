import 'package:flutter_test/flutter_test.dart';
import 'package:veto/screens/wizard/onboarding_wizard_screen.dart';

import 'e2e_test_bindings.dart';
import 'support/pump_veto_test_app.dart';

void main() {
  setUpAll(initE2ePluginMocks);

  testWidgets('/wizard_home mounts OnboardingWizardScreen', (tester) async {
    await pumpVetoTestApp(tester, initialRoute: '/wizard_home');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(OnboardingWizardScreen), findsOneWidget);
  });
}
