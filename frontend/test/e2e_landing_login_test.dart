// ============================================================
//  E2E: reach LoginScreen via named route (stable under tests).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veto/app_navigator.dart';
import 'package:veto/screens/login_screen.dart';

import 'e2e_test_bindings.dart';
import 'support/pump_veto_test_app.dart';

void main() {
  setUpAll(initE2ePluginMocks);

  testWidgets('navigator can reach LoginScreen', (tester) async {
    await pumpVetoTestApp(tester);

    expect(find.textContaining('VETO'), findsWidgets);

    vetoRootNavigatorKey.currentState!.pushNamed('/login');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(Material), findsWidgets);
  });
}
