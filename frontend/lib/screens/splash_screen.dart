// ============================================================
//  splash_screen.dart
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
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/wizard_home');
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
            SizedBox(height: 24),
            Text(
              'VETO',
              style: TextStyle(
                color: Color(0xFFC0C2C9),
                fontSize: 32,
                letterSpacing: 8.0,
                fontWeight: FontWeight.w200,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC0C2C9)),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
