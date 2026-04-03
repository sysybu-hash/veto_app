// ============================================================
//  splash_screen.dart — splash → token + role routing
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final auth = AuthService();
    final token = await auth.getToken();
    final role = await auth.getStoredRole();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      if (role == 'lawyer' || role == 'admin') {
        Navigator.pushReplacementNamed(context, '/lawyer_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/veto_screen');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF001F3F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 120, color: Color(0xFFC0C2C9)),
            SizedBox(height: 25),
            Text(
              'VETO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
