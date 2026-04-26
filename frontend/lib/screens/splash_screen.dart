import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';

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
    if (!mounted) return;
    // Always show the landing page — the NavBar detects auth state
    // and shows the appropriate "Enter App" / user bubble for logged-in users.
    Navigator.pushReplacementNamed(context, '/landing');
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
      backgroundColor: VetoGlassTokens.bgBase,
      body: VetoGlassAuroraBackground(
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
                    VetoGlassBlur(
                      borderRadius: 28,
                      sigma: VetoGlassTokens.blurSigma,
                      fill: VetoGlassTokens.glassFillStrong,
                      borderColor: VetoGlassTokens.glassBorderBright,
                      child: const SizedBox(
                        width: 96,
                        height: 96,
                        child: Center(
                          child: Icon(Icons.shield_rounded, color: VetoGlassTokens.neonCyan, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFCCFBF1),
                          VetoGlassTokens.neonCyan,
                          VetoGlassTokens.neonBlue,
                          VetoGlassTokens.violetGlow,
                        ],
                        stops: [0.0, 0.35, 0.7, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'VETO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 48,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: VetoGlassTokens.neonButton,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tagline,
                      style: const TextStyle(
                        color: VetoGlassTokens.textMuted,
                        fontSize: 13,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 56),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: VetoGlassTokens.neonCyan),
                    ),
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
