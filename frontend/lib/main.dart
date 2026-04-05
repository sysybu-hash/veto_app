// ============================================================
//  main.dart — VETO app entry + named routes
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/veto_theme.dart';
import 'screens/LoginScreen.dart';
import 'screens/LandingScreen.dart';
import 'screens/LawyerDashboard.dart';
import 'screens/splash_screen.dart';
import 'screens/VetoScreen.dart';
import 'screens/ProfileScreen.dart';
import 'screens/AdminSettingsScreen.dart';
import 'screens/wizard/WizardShellScreen.dart';

void main() {
  runApp(const VetoApp());
}

class VetoApp extends StatelessWidget {
  const VetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VETO',
      theme: VetoTheme.dark(),
      locale: const Locale('he'),
      supportedLocales: const [Locale('he'), Locale('en')],
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
