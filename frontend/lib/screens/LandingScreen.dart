// ============================================================
//  LandingScreen.dart — Public Landing Page (v2)
//  VETO Legal Emergency App
//  Redesigned: no duplicate buttons, fully responsive.
// ============================================================

import 'package:flutter/material.dart';

import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';

// Responsive breakpoints
const double _kMobile  = 600;

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _goToPersonalArea(BuildContext context) async {
    final token = await AuthService().getToken();
    if (!context.mounted) return;
    if (token != null && token.isNotEmpty) {
      final role = await AuthService().getStoredRole() ?? 'user';
      if (!context.mounted) return;
      switch (role) {
        case 'lawyer': Navigator.pushNamed(context, '/lawyer_dashboard'); break;
        case 'admin':  Navigator.pushNamed(context, '/admin_settings');   break;
        default:       Navigator.pushNamed(context, '/veto_screen');
      }
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        body: LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final onRegister   = () => Navigator.pushNamed(context, '/login');
            final onPersonal   = () => _goToPersonalArea(context);
            return SingleChildScrollView(
              child: Column(
                children: [
                  _NavBar(onLogin: onPersonal, screenWidth: w),
                  _HeroSection(screenWidth: w, onRegister: onRegister),
                  _PricingSection(screenWidth: w),
                  _HowToUseSection(screenWidth: w),
                  _FeaturesSection(screenWidth: w),
                  _HowItWorksSection(screenWidth: w),
                  _CtaSection(onRegister: onRegister, screenWidth: w),
                  const _Footer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  NavBar — only ONE button: "כניסה"
// ══════════════════════════════════════════════════════════════
class _NavBar extends StatelessWidget {
  final VoidCallback onLogin;
  final double screenWidth;
  const _NavBar({required this.onLogin, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final compact = screenWidth < _kMobile;
    return Container(
      decoration: const BoxDecoration(
        color: VetoPalette.surface,
        border: Border(bottom: BorderSide(color: VetoPalette.border)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 32,
        vertical: 14,
      ),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: VetoPalette.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.gavel_rounded, color: VetoPalette.primary, size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            'VETO',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: VetoPalette.text,
                ),
          ),
          const Spacer(),
          // Single nav button — "כניסה" only (register is in hero)
          FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: VetoPalette.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 20,
                vertical: 10,
              ),
              textStyle: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: const Text('כניסה'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Hero Section — single CTA "הרשמה חינמית"
// ══════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final double screenWidth;
  final VoidCallback onRegister;

  const _HeroSection({required this.screenWidth, required this.onRegister});

  bool get _wide => screenWidth >= _kMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VetoPalette.primary.withValues(alpha: 0.07),
            VetoPalette.bg,
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < _kMobile ? 20 : 40,
              vertical: _wide ? 80 : 48,
            ),
            child: _wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _HeroText(
                          onRegister: onRegister,
                          compact: screenWidth < _kMobile,
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 4,
                        child: _HeroVisual(),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroText(
                        onRegister: onRegister,
                        compact: screenWidth < _kMobile,
                      ),
                      const SizedBox(height: 32),
                      _HeroVisual(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final VoidCallback onRegister;
  final bool compact;
  const _HeroText({required this.onRegister, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: VetoPalette.emergency.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: VetoPalette.emergency,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'הגנה משפטית מידית · זמין 24/7',
                style: TextStyle(
                  color: VetoPalette.emergency,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Headline
        Text(
          'עורך דין בשניות,\nלא בשעות.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: VetoPalette.text,
                letterSpacing: -0.5,
                fontSize: compact ? 28 : null,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'VETO מחבר אותך לעורך דין מוסמך בזמן חירום באמצעות AI חכם, שיגור אוטומטי ותיעוד ראיות — הכל ממסך אחד.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: VetoPalette.textMuted,
                height: 1.6,
                fontSize: compact ? 14 : null,
              ),
        ),
        const SizedBox(height: 32),
        // Single CTA
        FilledButton.icon(
          onPressed: onRegister,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('הרשמו עכשיו'),
          style: FilledButton.styleFrom(
            backgroundColor: VetoPalette.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 14),
        // Pricing chips
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: const [
            _PriceChip(label: 'מנוי חודשי ‏₪19.90 בלבד'),
            _PriceChip(label: 'ייעוץ 15 דק — ‏₪50'),
          ],
        ),
        const SizedBox(height: 20),
        // Trust chips
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: const [
            _TrustChip(icon: Icons.lock_outline_rounded, label: 'מוצפן ומאובטח'),
            _TrustChip(icon: Icons.verified_outlined,    label: 'עורכי דין מוסמכים'),
            _TrustChip(icon: Icons.bolt_rounded,         label: 'תגובה מיידית'),
          ],
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  const _PriceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: VetoPalette.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: VetoPalette.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: VetoPalette.success),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13)),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [
          BoxShadow(
            color: VetoPalette.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Mock chat bubble — AI
          _MockBubble(
            text: 'שלום! תאר את הבעיה המשפטית שלך בכמה מילים.',
            isUser: false,
          ),
          const SizedBox(height: 10),
          _MockBubble(
            text: 'עצרתי על ידי המשטרה ואני צריך עזרה דחופה.',
            isUser: true,
          ),
          const SizedBox(height: 10),
          _MockBubble(
            text: 'מאתר עורך דין פלילי זמין בסביבתך...',
            isUser: false,
            isSystem: true,
          ),
          const SizedBox(height: 16),
          // Mock status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: VetoPalette.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VetoPalette.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: VetoPalette.success,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '✓  עורך דין נמצא — יוצר קשר',
                  style: TextStyle(
                    color: VetoPalette.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isSystem;
  const _MockBubble({required this.text, required this.isUser, this.isSystem = false});

  @override
  Widget build(BuildContext context) {
    if (isSystem) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: VetoPalette.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: VetoPalette.warning.withValues(alpha: 0.3)),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: VetoPalette.warning, fontSize: 12)),
      );
    }
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: isUser ? VetoPalette.surface2 : VetoPalette.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? VetoPalette.border : VetoPalette.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(text,
            style: TextStyle(
              color: isUser ? VetoPalette.text : VetoPalette.info,
              fontSize: 12,
            )),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Features Section — responsive grid via LayoutBuilder
// ══════════════════════════════════════════════════════════════
class _FeaturesSection extends StatelessWidget {
  final double screenWidth;
  const _FeaturesSection({required this.screenWidth});

  static const _features = [
    _Feature(
      icon: Icons.smart_toy_outlined,
      color: VetoPalette.primary,
      title: 'AI משפטי חכם',
      desc: 'צ\'אט AI שמבין את הבעיה שלך, מסווג את תחום המשפט ומוצא עורך דין מתאים תוך שניות.',
    ),
    _Feature(
      icon: Icons.bolt_rounded,
      color: VetoPalette.emergency,
      title: 'שיגור בזמן אמת',
      desc: 'מנוע שיגור חכם שמציג את החירום לעורכי דין זמינים — מי שמגיב ראשון מקבל את התיק.',
    ),
    _Feature(
      icon: Icons.camera_alt_outlined,
      color: VetoPalette.success,
      title: 'תיעוד ראיות',
      desc: 'צלם, הקלט ושמור ראיות ישירות מהאפליקציה עם חותמת GPS ותאריך — הכל מאובטח בענן.',
    ),
    _Feature(
      icon: Icons.location_on_outlined,
      color: VetoPalette.warning,
      title: 'שיתוף מיקום',
      desc: 'שיתוף GPS אוטומטי עם עורך הדין כדי לאפשר קשר מהיר ומדויק בשטח.',
    ),
    _Feature(
      icon: Icons.gavel_rounded,
      color: VetoPalette.violet,
      title: 'עורכי דין מאומתים',
      desc: 'כל עורך הדין ברשת VETO עבר אימות רישיון ומוסדר לפי תחום התמחות וזמינות.',
    ),
    _Feature(
      icon: Icons.history_edu_outlined,
      color: VetoPalette.info,
      title: 'היסטוריית אירועים',
      desc: 'כל שיחה, ראיה ותיק משפטי שמורים באיזור האישי שלך לצורכי מעקב ותיעוד.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VetoPalette.surface.withValues(alpha: 0.4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < _kMobile ? 20 : 40,
              vertical: 64,
            ),
            child: Column(
              children: [
                Text(
                  'כל מה שצריך בשעת חירום',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: VetoPalette.text,
                        fontSize: screenWidth < _kMobile ? 20 : null,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'VETO מספק את כל הכלים הדרושים להגנה משפטית מיידית',
                  style: TextStyle(color: VetoPalette.textMuted, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Responsive grid via LayoutBuilder
                LayoutBuilder(builder: (_, cons) {
                  final cols = cons.maxWidth >= 700
                      ? 3
                      : cons.maxWidth >= 440
                          ? 2
                          : 1;
                  if (cols == 1) {
                    return Column(
                      children: _features
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _FeatureCard(feature: f),
                              ))
                          .toList(),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: cols == 3 ? 1.5 : 1.9,
                    ),
                    itemCount: _features.length,
                    itemBuilder: (_, i) => _FeatureCard(feature: _features[i]),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _Feature({required this.icon, required this.color, required this.title, required this.desc});
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, color: feature.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(feature.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15, color: VetoPalette.text)),
          const SizedBox(height: 6),
          Text(feature.desc,
              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  How It Works
// ══════════════════════════════════════════════════════════════
class _HowItWorksSection extends StatelessWidget {
  final double screenWidth;
  const _HowItWorksSection({required this.screenWidth});

  static const _steps = [
    _Step(num: '01', title: 'תאר את הבעיה', desc: 'דבר עם ה-AI שלנו בעברית, ערבית או אנגלית — הוא יבין ויסווג את הצרך המשפטי.'),
    _Step(num: '02', title: 'קבל שיגור מיידי', desc: 'המערכת שולחת התראה לעורכי הדין הרלוונטיים הקרובים אליך שזמינים כרגע.'),
    _Step(num: '03', title: 'צור קשר', desc: 'עורך הדין שמגיב ראשון מחייג או מוואצ\'אפ ישירות — תוך דקות ספורות.'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = screenWidth >= _kMobile;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth < _kMobile ? 20 : 40,
            vertical: 64,
          ),
          child: Column(
            children: [
              Text('איך זה עובד?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: VetoPalette.text,
                      fontSize: screenWidth < _kMobile ? 20 : null,
                    ),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('שלושה צעדים פשוטים לקבלת ייצוג משפטי',
                style: TextStyle(color: VetoPalette.textMuted, fontSize: 15),
                textAlign: TextAlign.center),
              const SizedBox(height: 48),
              wide
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _steps
                            .asMap()
                            .entries
                            .map((e) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: e.key < _steps.length - 1 ? 16 : 0,
                                    ),
                                    child: _StepCard(step: e.value),
                                  ),
                                ))
                            .toList(),
                      ),
                    )
                  : Column(
                      children: _steps
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _StepCard(step: s),
                              ))
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  final String num;
  final String title;
  final String desc;
  const _Step({required this.num, required this.title, required this.desc});
}

class _StepCard extends StatelessWidget {
  final _Step step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.num,
              style: const TextStyle(
                color: VetoPalette.primary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              )),
          const SizedBox(height: 8),
          Text(step.title,
              style: const TextStyle(
                  color: VetoPalette.text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(step.desc,
              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CTA Section
// ══════════════════════════════════════════════════════════════
class _CtaSection extends StatelessWidget {
  final VoidCallback onRegister;
  final double screenWidth;
  const _CtaSection({required this.onRegister, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            VetoPalette.primary.withValues(alpha: 0.08),
            VetoPalette.emergency.withValues(alpha: 0.04),
          ],
        ),
        border: const Border(
          top: BorderSide(color: VetoPalette.border),
          bottom: BorderSide(color: VetoPalette.border),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < _kMobile ? 20 : 40,
              vertical: 72,
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: VetoPalette.emergency.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.shield_outlined, color: VetoPalette.emergency, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  'אל תחכה לרגע הקריטי',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: VetoPalette.text,
                        fontSize: screenWidth < _kMobile ? 20 : null,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'הצטרף עכשיו ויהיה לך עורך דין בהישג יד בכל עת.',
                  style: TextStyle(color: VetoPalette.textMuted, fontSize: 15, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '₪19.90 לחודש · ₪50 לייעוץ של 15 דקות',
                  style: TextStyle(
                    color: VetoPalette.textSubtle,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: const Text('הצטרף עכשיו'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VetoPalette.emergency,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Pricing Section
// ══════════════════════════════════════════════════════════════
class _PricingSection extends StatelessWidget {
  final double screenWidth;
  const _PricingSection({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final compact = screenWidth < _kMobile;
    return Container(
      width: double.infinity,
      color: VetoPalette.surface.withValues(alpha: 0.6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 20 : 40,
              vertical: 64,
            ),
            child: Column(
              children: [
                Text(
                  'מחירון ברור ושקוף',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: VetoPalette.text,
                        fontSize: compact ? 20 : null,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'ללא הפתעות — אתה יודע מראש בדיוק כמה תשלם',
                  style: TextStyle(color: VetoPalette.textMuted, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                compact
                    ? Column(children: const [
                        _PricingCard(
                          icon: Icons.star_border_rounded,
                          color: VetoPalette.primary,
                          title: 'מנוי חודשי',
                          price: '₪19.90',
                          period: 'לחודש',
                          desc: 'גישה מלאה לכל פיצ\'רי VETO: AI משפטי, שיגור עורכי דין, תיעוד ראיות והיסטוריה.',
                          badge: null,
                        ),
                        SizedBox(height: 14),
                        _PricingCard(
                          icon: Icons.gavel_rounded,
                          color: VetoPalette.warning,
                          title: 'ייעוץ עם עורך דין',
                          price: '₪50',
                          period: 'לייעוץ',
                          desc: 'שיחת ייעוץ של 15 דקות עם עורך דין מוסמך. החיוב מתבצע אוטומטית בלחיצה על "הזמן ייעוץ".',
                          badge: '15 דקות',
                        ),
                      ])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: _PricingCard(
                              icon: Icons.star_border_rounded,
                              color: VetoPalette.primary,
                              title: 'מנוי חודשי',
                              price: '₪19.90',
                              period: 'לחודש',
                              desc: 'גישה מלאה לכל פיצ\'רי VETO: AI משפטי, שיגור עורכי דין, תיעוד ראיות והיסטוריה.',
                              badge: null,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _PricingCard(
                              icon: Icons.gavel_rounded,
                              color: VetoPalette.warning,
                              title: 'ייעוץ עם עורך דין',
                              price: '₪50',
                              period: 'לייעוץ',
                              desc: 'שיחת ייעוץ של 15 דקות עם עורך דין מוסמך. החיוב מתבצע אוטומטית בלחיצה על "הזמן ייעוץ".',
                              badge: '15 דקות',
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: VetoPalette.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VetoPalette.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: VetoPalette.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'בכל לחיצה על "הזמן ייעוץ עו"ד" תחויב אוטומטית ב-₪50. אין אפשרות לביטול לאחר ביצוע ההזמנה. וודא שאתה בטוח לפני האישור.',
                          style: TextStyle(
                            color: VetoPalette.warning.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String price;
  final String period;
  final String desc;
  final String? badge;
  const _PricingCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.price,
    required this.period,
    required this.desc,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: VetoPalette.text,
                  ))),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  )),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(period,
                    style: const TextStyle(
                      color: VetoPalette.textMuted,
                      fontSize: 14,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc,
              style: const TextStyle(
                color: VetoPalette.textMuted,
                fontSize: 13,
                height: 1.6,
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  How To Use Section — detailed operation explanation
// ══════════════════════════════════════════════════════════════
class _HowToUseSection extends StatelessWidget {
  final double screenWidth;
  const _HowToUseSection({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final compact = screenWidth < _kMobile;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 40,
            vertical: 64,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text('תפעול האתר — מדריך מלא',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: VetoPalette.text,
                              fontSize: compact ? 20 : null,
                            ),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text('כל מה שצריך לדעת לפני שמתחילים',
                        style: TextStyle(color: VetoPalette.textMuted, fontSize: 15),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const _GuideItem(
                step: '1',
                title: 'הרשמה ומנוי',
                color: VetoPalette.primary,
                points: [
                  'לחץ על "הצטרף עכשיו" ומלא מספר טלפון.',
                  'קבל קוד OTP בSMS ואמת את החשבון.',
                  'המנוי עולה ₪19.90 לחודש ומתחדש אוטומטית.',
                  'ניתן לבחור תפקיד: משתמש רגיל או עורך דין.',
                ],
              ),
              const SizedBox(height: 20),
              const _GuideItem(
                step: '2',
                title: 'ייעוץ AI משפטי',
                color: VetoPalette.info,
                points: [
                  'מנויים פעילים יכולים להתייעץ עם ה-AI בכל נושא חוקי.',
                  'ה-AI מותאם לחוקי המדינה שבה המשתמש נמצא.',
                  'ניתן לשאול שאלות בעברית, אנגלית ורוסית.',
                  'הייעוץ כולל מידע על חוקים, זכויות ופרוצדורות.',
                ],
              ),
              const SizedBox(height: 20),
              const _GuideItem(
                step: '3',
                title: 'הזמנת ייעוץ עם עורך דין',
                color: VetoPalette.warning,
                points: [
                  'בלחיצה על "הזמן ייעוץ עו"ד" תחויב ₪50 מיד.',
                  'הייעוץ כולל שיחה של 15 דקות עם עורך דין מוסמך.',
                  'לא ניתן לבטל הזמנה לאחר אישורה.',
                  'עורך הדין ייצור קשר תוך דקות ספורות.',
                ],
              ),
              const SizedBox(height: 20),
              const _GuideItem(
                step: '4',
                title: 'שיגור חירום',
                color: VetoPalette.emergency,
                points: [
                  'לחץ על כפתור ה-SOS האדום בשעת חירום.',
                  'המערכת שולחת את המיקום שלך לעורכי הדין הקרובים.',
                  'עורך הדין הראשון שמאשר מקבל את התיק ומתקשר.',
                  'ניתן לתעד ראיות תוך כדי (תמונות, קול, וידאו).',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final String step;
  final String title;
  final Color color;
  final List<String> points;
  const _GuideItem({
    required this.step,
    required this.title,
    required this.color,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(step,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: VetoPalette.text,
                    )),
                const SizedBox(height: 10),
                ...points.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, left: 6),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(p,
                                style: const TextStyle(
                                  color: VetoPalette.textMuted,
                                  fontSize: 13,
                                  height: 1.5,
                                )),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Footer
// ══════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VetoPalette.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.gavel_rounded, color: VetoPalette.primary, size: 16),
                const SizedBox(width: 6),
                Text('VETO © ${DateTime.now().year}',
                    style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 13)),
              ]),
              const Text(
                'הגנה משפטית מיידית',
                style: TextStyle(color: VetoPalette.textSubtle, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
