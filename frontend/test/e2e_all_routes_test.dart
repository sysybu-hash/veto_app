// ============================================================
//  E2E-style smoke: each route in isolation (fresh app via pump).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veto/app_navigator.dart';

import 'e2e_test_bindings.dart';
import 'support/pump_veto_test_app.dart';

typedef _RouteCase = ({String route, Object? args, String label});

final List<_RouteCase> _kSmokeRoutes = <_RouteCase>[
  (route: '/landing', args: null, label: '/landing'),
  (route: '/login', args: null, label: '/login'),
  (route: '/call', args: null, label: '/call'),
  (route: '/privacy', args: null, label: '/privacy'),
  (route: '/terms', args: null, label: '/terms'),
  (route: '/wizard_home', args: null, label: '/wizard_home'),
  (route: '/emergency_wizard', args: null, label: '/emergency_wizard'),
  (route: '/veto_screen', args: null, label: '/veto_screen'),
  (route: '/veto_screen', args: <String, dynamic>{'wizard': true}, label: '/veto_screen (wizard)'),
  (route: '/profile', args: null, label: '/profile'),
  (route: '/admin_settings', args: null, label: '/admin_settings'),
  (route: '/files_vault', args: null, label: '/files_vault'),
  (route: '/legal_calendar', args: null, label: '/legal_calendar'),
  (route: '/legal_notebook', args: null, label: '/legal_notebook'),
  (route: '/admin_dashboard', args: null, label: '/admin_dashboard'),
  (route: '/admin_subscriptions', args: null, label: '/admin_subscriptions'),
  (route: '/settings', args: null, label: '/settings'),
  (route: '/admin_users', args: null, label: '/admin_users'),
  (route: '/admin_lawyers', args: null, label: '/admin_lawyers'),
  (route: '/admin_pending', args: null, label: '/admin_pending'),
  (route: '/admin_logs', args: null, label: '/admin_logs'),
  (route: '/lawyer_settings', args: null, label: '/lawyer_settings'),
  (route: '/maps', args: null, label: '/maps'),
  (route: '/shared_vault', args: null, label: '/shared_vault'),
  (route: '/citizen_contracts', args: null, label: '/citizen_contracts'),
  (route: '/citizen_tasks', args: null, label: '/citizen_tasks'),
  (route: '/citizen_contacts', args: null, label: '/citizen_contacts'),
  (route: '/citizen_notifications', args: null, label: '/citizen_notifications'),
  (route: '/citizen_reports', args: null, label: '/citizen_reports'),
  (route: '/citizen_tools', args: null, label: '/citizen_tools'),
  (route: '/security_center', args: null, label: '/security_center'),
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

  for (final rc in _kSmokeRoutes) {
    testWidgets('route ${rc.label} mounts (smoke)', (tester) async {
      await pumpVetoTestApp(tester);

      final nav = vetoRootNavigatorKey.currentState;
      expect(nav, isNotNull, reason: 'navigatorKey must be attached');

      final args = rc.args ?? _argsFor(rc.route);
      if (args != null) {
        nav!.pushReplacementNamed(rc.route, arguments: args);
      } else {
        nav!.pushReplacementNamed(rc.route);
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        find.byType(Material),
        findsWidgets,
        reason: 'Route ${rc.label} should build a Material subtree',
      );
    });
  }
}
