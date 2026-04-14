// ============================================================
//  main.dart — VETO app entry + named routes
// ============================================================

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'core/accessibility/accessibility_settings.dart';
import 'core/i18n/app_language.dart';
import 'core/theme/veto_theme.dart';
import 'widgets/accessibility_toolbar.dart';
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
import 'services/socket_service.dart';

/// Used by [AccessibilityToolbarHost] so modal routes attach to the app
/// [Navigator] overlay (the host sits beside the navigator in `MaterialApp.builder`).
final GlobalKey<NavigatorState> vetoRootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageController = AppLanguageController();
  final accessibilitySettings = AccessibilitySettings();
  // Load language, accessibility prefs, and warm up the backend concurrently.
  await Future.wait([
    languageController.load(),
    accessibilitySettings.hydrate(),
    _warmUpBackend(),
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageController),
        ChangeNotifierProvider.value(value: accessibilitySettings),
        Provider<SocketService>(
          create: (_) => SocketService(),
          lazy: true,
        ),
      ],
      child: const VetoApp(),
    ),
  );
}

/// Fire a lightweight /health GET to wake Render's free-tier instance
/// before the user tries to log in. Failures are silently ignored.
Future<void> _warmUpBackend() async {
  try {
    await http
        .get(Uri.parse(AppConfig.healthCheckUrl))
        .timeout(const Duration(seconds: 10));
  } catch (_) {}
}

class VetoApp extends StatelessWidget {
  const VetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguageController>();
    final a11y = context.watch<AccessibilitySettings>();
    final baseTheme = VetoTheme.luxuryLight();

    return MaterialApp(
      navigatorKey: vetoRootNavigatorKey,
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
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(combined),
            boldText: a11y.boldBody,
            highContrast: a11y.highContrast,
            disableAnimations: a11y.reduceMotion,
          ),
          child: AccessibilityToolbarHost(
            navigatorKey: vetoRootNavigatorKey,
            child: navigatorChild,
          ),
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
      },
    );
  }
}
