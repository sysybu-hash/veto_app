// ============================================================
//  main.dart — VETO app entry + named routes
// ============================================================

import 'package:flutter/material.dart';

import 'screens/LoginScreen.dart';
import 'screens/LawyerDashboard.dart';
import 'screens/splash_screen.dart';
import 'screens/VetoScreen.dart';
import 'screens/ProfileScreen.dart';
import 'screens/AdminSettingsScreen.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF001F3F),
        scaffoldBackgroundColor: const Color(0xFF001F3F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF001F3F)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/veto_screen': (context) => const VetoScreen(),
        '/lawyer_dashboard': (context) => const LawyerDashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/admin_settings': (context) => const AdminSettingsScreen(),
      },
    );
  }
}
