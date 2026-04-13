import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../services/auth_service.dart';
import '../core/theme/veto_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final tagline = switch (AppLanguage.normalize(code)) {
      'en' => 'Your legal response layer',
      'ru' => 'Ваш слой юридической защиты',
      _ => 'מערכת הגנת הזכויות שלך',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF07101C),
      body: Stack(
        children: [
          // Radial glow blob
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC9A050).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
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
                      // Logo mark
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC9A050), Color(0xFF8B6B1A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC9A050).withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: VetoColors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'VETO',
                        style: TextStyle(
                          color: VetoColors.accent,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                          shadows: [
                            Shadow(
                              color: VetoColors.accent.withOpacity(0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Gold decorative line
                      Container(
                        width: 48, height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, VetoColors.accent, Colors.transparent],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tagline,
                        style: const TextStyle(
                          color: VetoColors.silverDim,
          