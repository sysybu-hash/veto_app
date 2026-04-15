import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _fade;
  late Animation<double> _scale;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ac, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _ac, curve: const Interval(0, 0.7, curve: Curves.elasticOut)));
    _ac.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    final auth   = AuthService();
    final token  = await auth.getToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      final role = await auth.getStoredRole() ?? 'user';
      if (!mounted) return;
      if (role == 'lawyer') {
        Navigator.pushReplacementNamed(context, '/lawyer_dashboard');
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_settings');
      } else {
        // For regular users, always land on veto_screen
        // (subscription gate will handle unsubscribed users there)
        Navigator.pushReplacementNamed(context, '/veto_screen');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _ac.dispose();
    super.dispose();
  }

  Widget _blob(Color color, double size, double alpha) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withValues(alpha: alpha), Colors.transparent]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final tagline = switch (AppLanguage.normalize(code)) {
      'en' => 'Your legal response layer',
      'ru' => 'Ваш слой юридической защиты',
      _ => 'מערכת הגנת הזכויות שלך',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // Aurora blobs
          Positioned(top: -80, right: -80, child: _blob(const Color(0xFF38BDF8), 400, 0.20)),
          Positioned(bottom: -100, left: -60, child: _blob(const Color(0xFFA78BFA), 380, 0.16)),
          Positioned(top: 200, left: -60, child: _blob(const Color(0xFF5B8FFF), 300, 0.12)),
          Center(
            child: AnimatedBuilder(
              animation: _ac,
              builder: (_, __) => Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shield logo — white card with blue gradient icon
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE2E8F8), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF5B8FFF).withValues(alpha: 0.18), blurRadius: 32, spreadRadius: 0),
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.shield_rounded, color: Color(0xFF5B8FFF), size: 48),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'VETO',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Accent line
                      Container(
                        width: 48, height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.transparent, Color(0xFF5B8FFF), Colors.transparent]),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tagline,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 56),
                      const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B8FFF)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
