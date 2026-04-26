// ============================================================
//  Boots the same [MultiProvider] + [VetoApp] tree as production,
//  with a selectable [initialRoute] (default `/landing`) so E2E
//  avoids [SplashScreen] timers under widget test fake async.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;

import 'package:veto/core/accessibility/accessibility_settings.dart';
import 'package:veto/core/i18n/app_language.dart';
import 'package:veto/main.dart';
import 'package:veto/services/socket_service.dart';
import 'package:veto/services/vault_save_queue.dart';

Future<void> pumpVetoTestApp(
  WidgetTester tester, {
  String initialRoute = '/landing',
}) async {
  final languageController = AppLanguageController();
  final accessibilitySettings = AccessibilitySettings();
  await Future.wait([
    languageController.load(),
    accessibilitySettings.hydrate(),
  ]);

  await tester.pumpWidget(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider.value(value: languageController),
        provider.ChangeNotifierProvider.value(value: accessibilitySettings),
        provider.ChangeNotifierProvider<VaultSaveQueue>(
          create: (_) => VaultSaveQueue(),
        ),
        provider.Provider<SocketService>(
          create: (_) => SocketService(),
          lazy: true,
        ),
      ],
      child: VetoApp(initialRoute: initialRoute),
    ),
  );
  await tester.pump();
}
