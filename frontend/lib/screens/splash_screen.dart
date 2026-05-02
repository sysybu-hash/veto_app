// ============================================================
//  SplashScreen — VETO 2026
//  Pixel-aligned with design_mockups/2026/splash.html (light variant).
//
//  Layout (centred):
//    crest 120×120 (radius 30, navy-700→500 gradient, "V" Frank Ruhl Libre 64/900)
//    gap 28
//    title "VETO" Frank Ruhl Libre 42/900, ink-900, letter-spacing 1.7
//    gap 8
//    tagline Heebo 14/500, ink-500, letter-spacing 0.5
//    gap 36
//    spinner: 3 dots, 6×6, navy-500, staggered bounce 1.2s
//
//  Background: paper #F6F8FB + radial tint top-right (#E8F0FB) +
//              radial tint bottom-left (#F0E9DE).
// ============================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final AnimationController _dots;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entry,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _entry.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/landing');
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entry.dispose();
    _dots.dispose();
    super.dispose();
  }

  String _tagline(String code) {
    switch (AppLanguage.normalize(code)) {
      case 'en':
        return 'Your legal response layer';
      case 'ru':
        return 'Ваш слой юридической защиты';
      default:
        return 'מערכת הגנת הזכויות שלך';
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;

    return Scaffold(
      backgroundColor: VetoTokens.paper,
      body: Container(
        // Two soft radial tints — matches CSS:
        //   radial-gradient(900px 500px at 50% 30%, #E8F0FB → transparent)
        //   radial-gradient(700px 400px at 50% 90%, #F0E9DE → transparent)
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 0.9,
            colors: [Color(0xFFE8F0FB), Color(0x00E8F0FB)],
          ),
        ),
        foregroundDecoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.8),
            radius: 0.7,
            colors: [Color(0xFFF0E9DE), Color(0x00F0E9DE)],
          ),
          backgroundBlendMode: BlendMode.multiply,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _entry,
            builder: (_, __) => Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Crest(),
                    const SizedBox(height: 28),
                    Text(
                      'VETO',
                      style: VetoTokens.serif(
                        42,
                        FontWeight.w900,
                        color: VetoTokens.ink900,
                        height: 1.0,
                        letterSpacing: 1.7, // 0.04em ≈ 1.7px at 42
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tagline(code),
                      style: VetoTokens.sans(
                        14,
                        FontWeight.w500,
                        color: VetoTokens.ink500,
                        letterSpacing: 0.56, // 0.04em ≈ 0.56px at 14
                      ),
                    ),
                    const SizedBox(height: 36),
                    _Spinner(controller: _dots),
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

/// 120×120 brand crest with the "V" letter.
/// Matches `.crest-xl` in splash.html.
class _Crest extends StatelessWidget {
  const _Crest();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: VetoTokens.crestGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D264975), // rgba(38,73,117,.30)
            blurRadius: 50,
            offset: Offset(0, 20),
          ),
        ],
        // Subtle inner highlight ring (CSS: inset 0 0 0 1px rgba(255,255,255,.18))
        border: Border.all(color: const Color(0x2EFFFFFF), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        'V',
        style: VetoTokens.serif(
          64,
          FontWeight.w900,
          color: Colors.white,
          height: 1.0,
          letterSpacing: 2.56, // 0.04em
        ),
      ),
    );
  }
}

/// Three-dot pulse — matches `.splash-spinner` keyframes:
///   0%/80%/100% → opacity .25, translateY 0
///   40%         → opacity 1,   translateY -4px
/// Stagger: 0ms / 200ms / 400ms.
class _Spinner extends StatelessWidget {
  const _Spinner({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30, // 3×6 + 2×6 gap
      height: 14, // dot 6 + bounce 4 + headroom
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _dot(0.0),
              const SizedBox(width: 6),
              _dot(0.166), // 200ms / 1200ms
              const SizedBox(width: 6),
              _dot(0.333), // 400ms / 1200ms
            ],
          );
        },
      ),
    );
  }

  Widget _dot(double phaseOffset) {
    // Phase value cycles 0..1 with stagger.
    final p = (controller.value + phaseOffset) % 1.0;
    // Opacity: .25 baseline, peaks to 1.0 around 40%.
    final opacity = _bouncePhase(p, 0.25, 1.0);
    final lift = _bouncePhase(p, 0.0, 4.0);
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, -lift),
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: VetoTokens.navy500,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  /// Mimics CSS keyframes:
  ///   0%, 80%, 100% → low
  ///   40%           → high
  /// Smooth interpolation between key points.
  double _bouncePhase(double t, double low, double high) {
    if (t <= 0.4) {
      // 0 → 0.4 : low → high (eased)
      final k = t / 0.4;
      return low + (high - low) * Curves.easeOut.transform(k);
    } else if (t <= 0.8) {
      // 0.4 → 0.8 : high → low (eased)
      final k = (t - 0.4) / 0.4;
      return high - (high - low) * Curves.easeIn.transform(k);
    } else {
      return low;
    }
  }
}
