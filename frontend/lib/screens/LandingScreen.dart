// ============================================================
//  LandingScreen.dart — VETO Welcome / Onboarding Screen
//  New design: Luxury, Navy, animated
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  int _currentFeature = 0;
  final _features = [
    {
      'icon':  Icons.bolt,
      'title': 'עזרה משפטית בשניות',
      'sub':   'עורך דין זמין תוך דקות — 24/7',
      'color': VetoColors.vetoRed,
    },
    {
      'icon':  Icons.videocam_outlined,
      'title': 'שיחות אודיו ווידאו',
      'sub':   'ייעוץ פנים אל פנים ישירות מהאפליקציה',
      'color': VetoColors.accent,
    },
    {
      'icon':  Icons.mic_outlined,
      'title': 'הקלטה ותמלול אוטומטי',
      'sub':   'כל שיחה מוקלטת ומתומללת בשפתך',
      'color': VetoColors.success,
    },
    {
      'icon':  Icons.lock_outlined,
      'title': 'כספת מסמכים מאובטחת',
      'sub':   'כל הראיות שלך מוצפנות ובטוחות',
      'color': VetoColors.warning,
    },
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl  = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();

    // Auto-advance features
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      setState(() => _currentFeature = (_currentFeature + 1) % _features.length);
      return true;
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageController>();
    final isHe = lang.locale.languageCode == 'he';

    return Scaffold(
      backgroundColor: VetoColors.background,
      body: Container(
        decoration: VetoDecorations.gradientBg(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Logo ───────────────────────────────────────
                  _buildLogo(),

                  const Spacer(flex: 1),

                  // ── Feature cards ──────────────────────────────
                  _buildFeatureSection(),

                  const Spacer(flex: 2),

                  // ── CTA buttons ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VetoColors.vetoRed,
                              foregroundColor: VetoColors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'התחל עכשיו',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: VetoColors.accent,
                              side: const BorderSide(color: VetoColors.border, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text(
                              'כבר יש לי חשבון',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Language selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _langBtn(lang, 'he', 'עב'),
                      _langBtn(lang, 'en', 'EN'),
                      _langBtn(lang, 'ru', 'RU'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Terms
                  const Text(
                    'בהמשך אתה מסכים לתנאי השימוש ולמדיניות הפרטיות',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 11,
                      color: VetoColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Shield icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [VetoColors.vetoRed.withOpacity(0.2), VetoColors.vetoRedDeep.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: VetoColors.vetoRed.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.shield, color: VetoColors.vetoRed, size: 40),
        ),
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontFamily: 'Heebo', fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 6),
            children: [
              TextSpan(text: 'VE', style: TextStyle(color: VetoColors.white)),
              TextSpan(text: 'TO', style: TextStyle(color: VetoColors.vetoRed)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Legal Emergency · ייעוץ משפטי חירום',
          style: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 13,
            color: VetoColors.silverDim,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureSection() {
    final f = _features[_currentFeature];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentFeature),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VetoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (f['color'] as Color).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (f['color'] as Color).withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (f['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f['title'] as String,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: VetoColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f['sub'] as String,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 13,
                      color: VetoColors.silver,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langBtn(AppLanguageController lang, String code, String label) {
    final selected = lang.locale.languageCode == code;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => lang.setLanguage(code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? VetoColors.accent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? VetoColors.accent : VetoColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? VetoColors.accent : VetoColors.silverDim,
            ),
          ),
        ),
      ),
    );
  }
}
