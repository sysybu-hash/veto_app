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
import 'screens/LoginScreen.dart';
import 'screens/LandingScreen.dart';
import 'screens/LawyerDashboard.dart';
import 'screens/splash_screen.dart';
import 'screens/VetoScreen.dart';
import 'screens/ProfileScreen.dart';
import 'screens/AdminSettingsScreen.dart';
import 'screens/wizard/WizardShellScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageController = AppLanguageController();
  // Load language and warm up the backend concurrently.
  await Future.wait([
    languageController.load(),
    _warmUpBackend(),
  ]);
  runApp(
    ChangeNotifierProvider.value(
      value: languageController,
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
      },
    );
  }
}
