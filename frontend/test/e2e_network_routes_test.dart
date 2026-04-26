// ============================================================
//  Optional: Socket/WebRTC-heavy routes (skipped by default).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veto/app_navigator.dart';

import 'e2e_test_bindings.dart';
import 'support/pump_veto_test_app.dart';

const _kNetworkHeavyRoutes = <String>[
  '/wizard_home',
  '/veto_screen',
  '/lawyer_dashboard',
  '/chat',
  '/call',
];

Object? _argsFor(String route) {
  switch (route) {
    case '/call':
      return <String, dynamic>{
        'roomId': 'e2e-room',
        'callType': 'chat',
        'peerName': 'E2E',
        'role': 'user',
        'eventId': '',
        'language': 'he',
      };
    default:
      return null;
  }
}

void main() {
  setUpAll(initE2ePluginMocks);

  testWidgets(
    'network-heavy routes mount (optional)',
    (tester) async {
      await pumpVetoTestApp(tester);

      final nav = vetoRootNavigatorKey.currentState;
      expect(nav, isNotNull);

      for (final route in _kNetworkHeavyRoutes) {
        final args = _argsFor(route);
        if (args != null) {
          nav!.pushReplacementNamed(route, arguments: args);
        } else {
          nav!.pushReplacementNamed(route);
        }
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));
        expect(find.byType(Material), findsWidgets, reason: route);
      }
    },
    skip: true,
  );
}
