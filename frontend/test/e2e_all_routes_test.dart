// ============================================================
//  E2E-style smoke: each route in isolation (fresh app via pump).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veto/app_navigator.dart';

import 'e2e_test_bindings.dart';
import 'support/pump_veto_test_app.dart';

const _kSmokeRoutes = <String>[
  '/landing',
  '/login',
  '/call',
  '/privacy',
  '/terms',
  '/wizard_home',
  '/emergency_wizard',
  '/veto_screen',
  '/profile',
  '/admin_settings',
  '/files_vault',
  '/legal_calendar',
  '/legal_notebook',
  '/admin_dashboard',
  '/admin_subscriptions',
  '/settings',
  '/admin_users',
  '/admin_lawyers',
  '/admin_pending',
  '/admin_logs',
  '/lawyer_settings',
  '/maps',
  '/shared_vault',
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
    case '/maps':
      return <String, dynamic>{'lat': 32.0853, 'lng': 34.7818};
    case '/shared_vault':
      return <String, dynamic>{
        'userId': 'e2e-user',
        'userName': 'E2E',
      };
    default:
      return null;
  }
}

void main() {
  setUpAll(initE2ePluginMocks);

  for (final route in _kSmokeRoutes) {
    testWidgets('route $route mounts (smoke)', (tester) async {
      await pumpVetoTestApp(tester);

      final nav = vetoRootNavigatorKey.currentState;
      expect(nav, isNotNull, reason: 'navigatorKey must be attached');

      final args = _argsFor(route);
      if (args != null) {
        nav!.pushReplacementNamed(route, arguments: args);
      } else {
        nav!.pushReplacementNamed(route);
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        find.byType(Material),
        findsWidgets,
        reason: 'Route $route should build a Material subtree',
      );
    });
  }
}
