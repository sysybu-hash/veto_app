import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ac, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _ac, curve: const Interval(0, 0.7, curve: Curves.elasticOut)));
    _ac.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    final auth   = AuthService();
    final token  = await auth.getToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      final role = await auth.getStoredRole() ?? 'user';
      if (!mounted) return;
      if (role == 'lawyer') {
        Navigator.pushReplacementNamed(context, '/lawyer_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/veto_screen');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VetoPalette.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ac,
          builder: (_, __) => Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VetoPalette.primary.withValues(alpha: 0.12),
                    border: Border.all(
                        color: VetoPalette.primary.withValues(alpha: 0.4), width: 2),
                    boxShadow: [BoxShadow(
                        color: VetoPalette.primary.withValues(alpha: 0.25),
                        blurRadius: 32, spreadRadius: 4)],
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: VetoPalette.primary, size: 52),
                ),
                const SizedBox(height: 24),
                const Text('VETO',
                    style: TextStyle(
                        color: VetoPalette.text,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 10)),
                const SizedBox(height: 6),
                const Text('\u05DE\u05E2\u05E8\u05DB\u05EA \u05D4\u05D2\u05E0\u05EA \u05D4\u05D6\u05DB\u05D5\u05D9\u05D5\u05EA \u05E9\u05DC\u05DA',
                    style: TextStyle(
                        color: VetoPalette.textMuted,
                        fontSize: 13,
                        letterSpacing: 1)),
                const SizedBox(height: 48),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VetoPalette.primary.withValues(alpha: 0.5)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
