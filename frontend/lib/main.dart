// ============================================================
//  main.dart — VETO app entry + named routes
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'core/i18n/app_language.dart';
import 'core/theme/veto_theme.dart';
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
import 'services/socket_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageController = AppLanguageController();
  // Load language and warm up the backend concurrently.
  await Future.wait([
    languageController.load(),
    _warmUpBackend(),
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageController),
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VETO',
      theme: VetoTheme.dark(),
      locale: language.locale,
      supportedLocales: const [Locale('he'), Locale('en'), Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      },
    );
  }
}
