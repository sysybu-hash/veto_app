// ============================================================
//  main.dart — VETO app entry + named routes
// ============================================================

import 'dart:async' show unawaited;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as provider;

import 'config/app_config.dart';
import 'core/accessibility/accessibility_settings.dart';
import 'core/i18n/app_language.dart';
import 'core/theme/veto_theme.dart';
import 'core/theme/veto_glass_system.dart';
import 'screens/login_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/lawyer_dashboard.dart';
import 'screens/splash_screen.dart';
import 'screens/veto_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'screens/wizard/wizard_shell_screen.dart';
import 'screens/files_vault_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/subscription_admin_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin/all_lawyers_screen.dart';
import 'screens/admin/all_users_screen.dart';
import 'screens/admin/pending_lawyers_screen.dart';
import 'screens/admin/emergency_logs_screen.dart';
import 'screens/lawyer_settings_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/call_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/shared_vault_screen.dart';
import 'services/socket_service.dart';
import 'services/vault_save_queue.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Boundary to prevent Red Screen of Death
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: VetoGlassTokens.bgBase,
      child: Container(
        color: VetoGlassTokens.bgBase,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 64),
            const SizedBox(height: 24),
            const Text(
              'משהו השתבש',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: VetoGlassTokens.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'אנחנו עובדים על זה. נסה לרענן את העמוד.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: VetoGlassTokens.textMuted),
            ),
            const SizedBox(height: 24),
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: VetoGlassTokens.textSubtle, fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  };

  final languageController = AppLanguageController();
  final accessibilitySettings = AccessibilitySettings();
  // Load language + a11y — do *not* block the first frame on /health (can hang ~10s if API/tunnel is down).
  await Future.wait([
    languageController.load(),
    accessibilitySettings.hydrate(),
  ]);
  unawaited(_warmUpBackend());
  runApp(
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
      child: const VetoApp(),
    ),
  );
}

/// Fire a lightweight /health GET to wake Render (or verify localhost). Runs in the
/// background so startup never waits on a dead tunnel or slow network.
/// Uses [AppConfig.httpGetHeaders] so localtunnel requests are not stuck on the reminder page.
Future<void> _warmUpBackend() async {
  try {
    await http
        .get(
          Uri.parse(AppConfig.healthCheckUrl),
          headers: AppConfig.httpGetHeaders,
        )
        .timeout(const Duration(seconds: 3));
  } catch (_) {}
}

class VetoApp extends StatelessWidget {
  const VetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = provider.Provider.of<AppLanguageController>(context);
    final a11y = provider.Provider.of<AccessibilitySettings>(context);
    final baseTheme = VetoTheme.glassDark();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VETO',
      theme: a11y.mergeTheme(baseTheme),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      locale: language.locale,
      supportedLocales: const [Locale('he'), Locale('en'), Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final navigatorChild = child ?? const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        // Respect OS font scaling, then apply in-app size steps.
        final os = mq.textScaler.scale(1.0);
        final combined = (os * a11y.textScale).clamp(0.75, 2.25);
        // Floating accessibility FAB + bottom sheet removed: on Web it could leave a
        // full-screen modal barrier with no usable sheet. Preferences still load via
        // [AccessibilitySettings] (theme + text scaler). Re-introduce as a dedicated
        // route (/accessibility) when needed — do not wrap the navigator in a Stack FAB.
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(combined),
            boldText: a11y.boldBody,
            highContrast: a11y.highContrast,
            disableAnimations: a11y.reduceMotion,
          ),
          child: navigatorChild,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/wizard_home': (context) => const WizardShellScreen(),
        '/veto_screen': (context) => const VetoScreen(),
        '/lawyer_dashboard': (context) => const LawyerDashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/admin_settings': (context) => const AdminSettingsScreen(),
        '/files_vault': (context) => const FilesVaultScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/admin_subscriptions': (context) => const SubscriptionAdminScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/admin_users': (context) => const AllUsersScreen(),
        '/admin_lawyers': (context) => const AllLawyersScreen(),
        '/admin_pending': (context) => const PendingLawyersScreen(),
        '/admin_logs': (context) => const EmergencyLogsScreen(),
        '/lawyer_settings': (context) => const LawyerSettingsScreen(),
        '/chat': (context) => const ChatScreen(),
        '/call': (context) => const CallScreen(),
        '/maps': (context) => const MapsScreen(),
        '/shared_vault': (context) => const SharedVaultScreen(),
      },
    );
  }
}
