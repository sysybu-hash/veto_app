import 'package:flutter/material.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _goLogin(BuildContext context) async {
    final token = await AuthService().getToken();
    if (!context.mounted) return;
    if (token != null && token.isNotEmpty) {
      final role = await AuthService().getStoredRole() ?? 'user';
      if (!context.mounted) return;
      switch (role) {
        case 'lawyer': Navigator.pushNamed(context, '/lawyer_dashboard'); break;
        case 'admin':  Navigator.pushNamed(context, '/veto_screen');      break;
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
        body: SingleChildScrollView(child: Column(children: [
          _LandingNav(onLogin: () => _goLogin(context)),
          _LandingHero(onCta: () => Navigator.pushNamed(context, '/login')),
          _LandingFeatures(),
          _LandingPricing(onCta: () => Navigator.pushNamed(context, '/login')),
          _LandingHowItWorks(),
          _LandingCta(onCta: () => Navigator.pushNamed(context, '/login')),
          _LandingFooter(),
        ])),
      ),
    );
  }
}

// ── Nav ───────────────────────────────────────────────────────
class _LandingNav extends StatelessWidget {
  final VoidCallback onLogin;
  const _LandingNav({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: VetoPalette.surface,
        border: Border(bottom: BorderSide(color: VetoPalette.border)),
      ),
      child: Row(children: [
        const Icon(Icons.shield_rounded, color: VetoPalette.primary, size: 24),
        const SizedBox(width: 8),
        const Text('VETO',
            style: TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w900,
                fontSize: 20, letterSpacing: 4)),
        const Spacer(),
        TextButton(
          onPressed: onLogin,
          child: const Text('\u05DB\u05E0\u05D9\u05E1\u05D4',
              style: TextStyle(color: VetoPalette.primary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onLogin,
          style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('\u05D4\u05EA\u05D7\u05DC \u05E2\u05DB\u05E9\u05D9\u05D5',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────
class _LandingHero extends StatelessWidget {
  final VoidCallback onCta;
  const _LandingHero({required this.onCta});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 640;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: compact ? 24 : 80, vertical: compact ? 60 : 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [VetoPalette.bg, const Color(0xFF0C1A2E)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: VetoPalette.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.3)),
          ),
          child: const Text('\u05DE\u05E2\u05E8\u05DB\u05EA \u05E9\u05D9\u05DC\u05D3 \u05DE\u05E9\u05E4\u05D8\u05D9 24/7',
              style: TextStyle(color: VetoPalette.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 24),
        Text(
          '\u05E2\u05D5\u05E8\u05DA \u05D3\u05D9\u05DF \u05D1\u05D7\u05D9\u05E8\u05D5\u05DD\n\u05D1\u05DC\u05D7\u05D9\u05E6\u05EA \u05DB\u05E4\u05EA\u05D5\u05E8 \u05D0\u05D7\u05D3',
          style: TextStyle(
              color: VetoPalette.text,
              fontSize: compact ? 32 : 52,
              fontWeight: FontWeight.w900,
              height: 1.15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          '\u05E2\u05E6\u05D5\u05E8 \u05D1\u05DE\u05E9\u05D8\u05E8\u05D4? \u05D4\u05EA\u05D0\u05D5\u05E0\u05D4? \u05D7\u05E7\u05D9\u05E8\u05D4? — VETO \u05DE\u05E9\u05D2\u05E8 \u05E2\u05D5\u05E8\u05DA \u05D3\u05D9\u05DF \u05DC\u05E2\u05DE\u05D3\u05EA\u05DA \u05D1\u05D3\u05E7\u05D5\u05EA.',
          style: TextStyle(color: VetoPalette.textMuted, fontSize: 16, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          FilledButton.icon(
            onPressed: onCta,
            icon: const Icon(Icons.shield_rounded, size: 18),
            label: const Text('\u05D4\u05EA\u05D7\u05DC \u05DC\u05D4\u05E9\u05EA\u05DE\u05E9 — \u05D1\u05D7\u05D9\u05E0\u05DD',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
                backgroundColor: VetoPalette.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
          ),
        ]),
        const SizedBox(height: 24),
        Wrap(spacing: 24, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _badge(Icons.check_circle_outline, '\u05D0\u05D9\u05DF \u05E6\u05D5\u05E8\u05DA \u05D1\u05DB\u05E8\u05D8\u05D9\u05E1'),
          _badge(Icons.check_circle_outline, '\u05E2\u05D5\u05E8\u05DA \u05D3\u05D9\u05DF \u05D1\u05D3\u05E7\u05D5\u05EA'),
          _badge(Icons.check_circle_outline, '24/7 \u05D6\u05DE\u05D9\u05DF'),
        ]),
      ]),
    );
  }

  Widget _badge(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: VetoPalette.success, size: 15),
    const SizedBox(width: 5),
    Text(text, style: const TextStyle(color: VetoPalette.textMuted, fontSize: 13)),
  ]);
}

// ── Features ──────────────────────────────────────────────────
class _LandingFeatures extends StatelessWidget {
  const _LandingFeatures();

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.crisis_alert_rounded, VetoPalette.emergency,
        '\u05E9\u05D9\u05D2\u05D5\u05E8 SOS',
        '\u05DC\u05D7\u05D9\u05E6\u05D4 \u05D0\u05D7\u05EA — \u05E2\u05D5\u05E8\u05DA \u05D3\u05D9\u05DF \u05DE\u05D2\u05D9\u05E2 \u05DC\u05E2\u05DE\u05D3\u05EA\u05DA \u05D1\u05D3\u05E7\u05D5\u05EA'
      ),
      (Icons.verified_user_outlined, VetoPalette.primary,
        '\u05D6\u05DB\u05D5\u05D9\u05D5\u05EA \u05DC\u05E4\u05D9 \u05EA\u05E8\u05D7\u05D9\u05E9',
        '\u05DE\u05D3\u05E8\u05D9\u05DA \u05E9\u05DC\u05D1 \u05D0\u05D7\u05E8 \u05E9\u05DC\u05D1 \u05DC\u05E4\u05D9 \u05E1\u05D9\u05D8\u05D5\u05D0\u05E6\u05D9\u05D4'
      ),
      (Icons.chat_bubble_outline, const Color(0xFF25D366),
        'WhatsApp / Telegram',
        '\u05E9\u05DC\u05D7 \u05D1\u05E7\u05E9\u05EA \u05E2\u05D6\u05E8\u05D4 \u05D1\u05E8\u05D2\u05E2 \u05DC\u05D0\u05E0\u05E9\u05D9\u05DD \u05E9\u05DC\u05DA'
      ),
      (Icons.camera_alt_outlined, VetoPalette.warning,
        '\u05EA\u05D9\u05E2\u05D5\u05D3 \u05E8\u05D0\u05D9\u05D5\u05EA',
        '\u05E6\u05DC\u05DD, \u05D4\u05E7\u05DC\u05D8 \u05D5\u05E9\u05DE\u05D5\u05E8 \u05E8\u05D0\u05D9\u05D5\u05EA \u05DE\u05D0\u05D5\u05D1\u05D8\u05D7\u05D5\u05EA'
      ),
      (Icons.location_on_outlined, VetoPalette.success,
        '\u05E9\u05D9\u05EA\u05D5\u05E3 \u05DE\u05D9\u05E7\u05D5\u05DD',
        '\u05E9\u05DC\u05D7 \u05E7\u05D9\u05E9\u05D5\u05E8 GPS \u05DC\u05D0\u05E0\u05E9\u05D9\u05DD \u05E9\u05D0\u05E0\u05D5 \u05D1\u05D5\u05D8\u05D7\u05D9\u05DD'
      ),
      (Icons.smart_toy_outlined, VetoPalette.info,
        '\u05E2\u05D5\u05D6\u05E8 AI \u05DE\u05E9\u05E4\u05D8\u05D9',
        '\u05D9\u05E2\u05D5\u05E5 \u05DE\u05D9\u05D9\u05D3\u05D9 \u05D1\u05E2\u05D1\u05E8\u05D9\u05EA, \u05E8\u05D5\u05E1\u05D9\u05EA \u05D5\u05D0\u05E0\u05D2\u05DC\u05D9\u05EA'
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      color: VetoPalette.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(children: [
            const Text('\u05D4\u05DB\u05DC \u05D1\u05E4\u05DC\u05D8\u05E4\u05D5\u05E8\u05DE\u05D0 \u05D0\u05D7\u05EA',
                style: TextStyle(color: VetoPalette.text, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('\u05DB\u05DC\u05D9\u05DD \u05DE\u05E9\u05E4\u05D8\u05D9\u05D9\u05DD \u05D1\u05DB\u05D9\u05E1\u05DA',
                style: TextStyle(color: VetoPalette.textMuted, fontSize: 14)),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (ctx, c) {
                final cols = c.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols, childAspectRatio: 1.4,
                      crossAxisSpacing: 14, mainAxisSpacing: 14),
                  itemCount: features.length,
                  itemBuilder: (_, i) {
                    final (icon, color, title, desc) = features[i];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: VetoPalette.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: VetoPalette.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(height: 12),
                        Text(title,
                            style: const TextStyle(color: VetoPalette.text,
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(desc,
                            style: const TextStyle(color: VetoPalette.textMuted,
                                fontSize: 11, height: 1.5),
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                      ]),
                    );
                  },
                );
              },
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Pricing ───────────────────────────────────────────────────
class _LandingPricing extends StatelessWidget {
  final VoidCallback onCta;
  const _LandingPricing({required this.onCta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(children: [
            const Text('\u05EA\u05DE\u05D7\u05D5\u05E8\u05D9\u05DD \u05E4\u05E9\u05D5\u05D8\u05D9\u05DD',
                style: TextStyle(color: VetoPalette.text, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 36),
            Row(children: [
              Expanded(child: _priceCard(
                '\u05D1\u05E1\u05D9\u05E1\u05D9', '0', '\u05DC\u05DC\u05D0 \u05E2\u05DC\u05D5\u05EA',
                ['\u05D9\u05E2\u05D5\u05E5 AI \u05D1\u05E1\u05D9\u05E1\u05D9',
                 '\u05E6\u05E4\u05D9\u05D9\u05D4 \u05D1\u05D6\u05DB\u05D5\u05D9\u05D5\u05EA',
                 '\u05D0\u05E4\u05DC\u05D9\u05E7\u05E6\u05D9\u05D9\u05EA \u05DE\u05D5\u05D1\u05D9\u05D9\u05DC'],
                isPrimary: false, onTap: onCta,
              )),
              const SizedBox(width: 16),
              Expanded(child: _priceCard(
                '\u05E4\u05E8\u05D5',
                '19.90',
                '\u05DC\u05D7\u05D5\u05D3\u05E9',
                ['\u05DB\u05DC \u05D4\u05D9\u05DB\u05D5\u05DC\u05D5\u05EA \u05D4\u05D1\u05E1\u05D9\u05E1\u05D9',
                 'SOS \u05E9\u05D9\u05D2\u05D5\u05E8 \u05E2\u05D5\u05E8\u05DA \u05D3\u05D9\u05DF',
                 '\u05E9\u05D9\u05D7\u05EA \u05D5\u05D9\u05D3\u05D0\u05D5 24/7',
                 '\u05EA\u05D9\u05E2\u05D5\u05D3 \u05E8\u05D0\u05D9\u05D5\u05EA \u05E1\u05DB\u05D5\u05E8'],
                isPrimary: true, onTap: onCta,
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _priceCard(String plan, String price, String period, List<String> items,
      {required bool isPrimary, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPrimary ? VetoPalette.primary : VetoPalette.border,
            width: isPrimary ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isPrimary)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: VetoPalette.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6)),
            child: const Text('\u05DE\u05D5\u05DE\u05DC\u05E5',
                style: TextStyle(color: VetoPalette.primary, fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        Text(plan,
            style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\u20aa$price',
              style: TextStyle(
                  color: isPrimary ? VetoPalette.primary : VetoPalette.text,
                  fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('/$period',
                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 16),
        ...items.map((i) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(children: [
            Icon(Icons.check_circle_outline, size: 14,
                color: isPrimary ? VetoPalette.primary : VetoPalette.success),
            const SizedBox(width: 8),
            Expanded(child: Text(i,
                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12))),
          ]),
        )),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: isPrimary
              ? FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary),
                  child: const Text('\u05D4\u05EA\u05D7\u05DC \u05E2\u05DB\u05E9\u05D9\u05D5',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                )
              : OutlinedButton(
                  onPressed: onTap,
                  child: const Text('\u05D4\u05EA\u05D7\u05DC \u05D1\u05D7\u05D9\u05E0\u05DD'),
                ),
        ),
      ]),
    );
  }
}

// ── How it works ─────────────────────────────────────────────
class _LandingHowItWorks extends StatelessWidget {
  const _LandingHowItWorks();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.login_rounded, '\u05D4\u05E8\u05E9\u05DD \u05D1\u05D7\u05D9\u05E0\u05DD', '\u05D8\u05DC\u05E4\u05D5\u05DF + SMS \u05DC\u05D0\u05D9\u05DE\u05D5\u05EA. \u05D0\u05D9\u05DF \u05E6\u05D5\u05E8\u05DA \u05D1\u05DB\u05E8\u05D8\u05D9\u05E1 \u05D0\u05E9\u05E8\u05D0\u05D9.'),
      (Icons.touch_app_rounded, '\u05D1\u05D7\u05E8 \u05E1\u05D9\u05D8\u05D5\u05D0\u05E6\u05D9\u05D4', '\u05E2\u05E6\u05D9\u05E8\u05EA \u05EA\u05E0\u05D5\u05E2\u05D4, \u05D7\u05E7\u05D9\u05E8\u05D4, \u05DE\u05E2\u05E6\u05E8, \u05EA\u05D0\u05D5\u05E0\u05D4 — \u05D5\u05E7\u05D1\u05DC \u05D4\u05E0\u05D7\u05D9\u05D5\u05EA.'),
      (Icons.crisis_alert_rounded, '\u05DC\u05D7\u05E5 SOS', '\u05E2\u05D5\u05E8\u05DA \u05D3\u05D9\u05DF \u05DE\u05D5\u05E9\u05D2\u05E8 \u05DC\u05E2\u05DE\u05D3\u05EA\u05DA \u05D1\u05D3\u05E7\u05D5\u05EA \u05E2\u05DD \u05D4\u05E2\u05E0\u05D9\u05D9\u05DF.'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      color: VetoPalette.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(children: [
            const Text('\u05D0\u05D9\u05DA \u05D6\u05D4 \u05E2\u05D5\u05D1\u05D3?',
                style: TextStyle(color: VetoPalette.text, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 36),
            LayoutBuilder(builder: (ctx, c) {
              final compact = c.maxWidth < 600;
              if (compact) {
                return Column(children: steps.asMap().entries.map((e) =>
                    _step(e.key + 1, e.value.$1, e.value.$2, e.value.$3)).toList());
              }
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.asMap().entries.expand((e) {
                    final widgets = <Widget>[
                      Expanded(child: _step(e.key + 1, e.value.$1, e.value.$2, e.value.$3))
                    ];
                    if (e.key < steps.length - 1)
                      widgets.add(const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Icon(Icons.arrow_back_ios_rounded,
                              color: VetoPalette.border, size: 16)));
                    return widgets;
                  }).toList());
            }),
          ]),
        ),
      ),
    );
  }

  Widget _step(int n, IconData icon, String title, String desc) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(children: [
      Stack(alignment: Alignment.topLeft, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: VetoPalette.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.3))),
          child: Icon(icon, color: VetoPalette.primary, size: 24),
        ),
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
              color: VetoPalette.primary, shape: BoxShape.circle),
          child: Center(child: Text('$n',
              style: const TextStyle(color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w800))),
        ),
      ]),
      const SizedBox(height: 14),
      Text(title,
          style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w700,
              fontSize: 14)),
      const SizedBox(height: 6),
      Text(desc,
          style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12,
              height: 1.5),
          textAlign: TextAlign.center),
    ]),
  );
}

// ── CTA ───────────────────────────────────────────────────────
class _LandingCta extends StatelessWidget {
  final VoidCallback onCta;
  const _LandingCta({required this.onCta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [VetoPalette.primary.withValues(alpha: 0.2),
                     VetoPalette.primary.withValues(alpha: 0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        const Text('\u05DE\u05D5\u05DB\u05DF \u05DC\u05D4\u05EA\u05D7\u05D9\u05DC?',
            style: TextStyle(color: VetoPalette.text, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text('\u05D4\u05D2\u05E0\u05EA \u05D4\u05D6\u05DB\u05D5\u05D9\u05D5\u05EA \u05E9\u05DC\u05DA \u05DE\u05EA\u05D7\u05D9\u05DC\u05D4 \u05E2\u05DB\u05E9\u05D9\u05D5.',
            style: TextStyle(color: VetoPalette.textMuted, fontSize: 14)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onCta,
          icon: const Icon(Icons.shield_rounded, size: 18),
          label: const Text('\u05D4\u05E6\u05D8\u05E8\u05E3 \u05DC-VETO',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: FilledButton.styleFrom(
              backgroundColor: VetoPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
        ),
      ]),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────
class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: VetoPalette.border))),
      child: const Center(
        child: Text('© 2026 VETO — \u05DB\u05DC \u05D4\u05D6\u05DB\u05D5\u05D9\u05D5\u05EA \u05E9\u05DE\u05D5\u05E8\u05D5\u05EA',
            style: TextStyle(color: VetoPalette.textSubtle, fontSize: 12)),
      ),
    );
  }
}
