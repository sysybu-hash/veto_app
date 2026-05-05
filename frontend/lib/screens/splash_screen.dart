import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_2026_splash.dart';
import '../core/theme/veto_mockup_tokens.dart';

/// Splash — matches `2026/splash.html` (light · crest-xl · 3 dots · 1.8s).
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
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ac,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _ac,
        curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _ac.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/landing');
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _ac.dispose();
    super.dispose();
  }

  String _tagline(String code) {
    return switch (AppLanguage.normalize(code)) {
      'en' => 'Your rights protection system',
      'ru' => 'Система защиты ваших прав',
      _ => 'מערכת הגנת הזכויות שלך',
    };
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;

    return Scaffold(
      backgroundColor: VetoMockup.pageBackground,
      body: V26SplashStage(
        child: Center(
          child: AnimatedBuilder(
            animation: _ac,
            builder: (_, __) => Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const V26SplashCrest(),
                    const SizedBox(height: 28),
                    const Text(
                      'VETO',
                      style: TextStyle(
                        fontFamily: V26.serif,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: V26.ink900,
                        letterSpacing: 0.04 * 42,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tagline(code),
                      style: const TextStyle(
                        fontFamily: V26.sans,
                        color: V26.ink500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.56,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const V26SplashDots(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
