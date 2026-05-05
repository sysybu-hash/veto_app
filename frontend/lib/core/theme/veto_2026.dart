// ============================================================
//  veto_2026.dart — VETO 2026 Design System
//  Mirror of repo-root `2026/_veto-2026.css` (same tokens as `:root`).
//  HTML mockups + screen index: `2026/00_index.html`.
//  Professional-Luxury · Light · Pango-inspired
// ============================================================

import 'package:flutter/material.dart';

import 'veto_mockup_tokens.dart';

/// ════════════════════════════════════════════════════════════
///  V26 — Design tokens (colors, shadows, radii, spacing, type)
///  1:1 mirror of `_veto-2026.css` `:root` variables.
/// ════════════════════════════════════════════════════════════
class V26 {
  V26._();

  // ── Brand · Navy ladder ─────────────────────────────────
  static const Color navy900 = Color(0xFF0E1F37);
  static const Color navy800 = Color(0xFF13284A);
  static const Color navy700 = Color(0xFF1B3A66);
  static const Color navy600 = Color(0xFF264975); // PRIMARY brand
  static const Color navy500 = Color(0xFF2E69E7); // link/interactive
  static const Color navy400 = Color(0xFF5B8BF0);
  static const Color navy300 = Color(0xFF83B7F8);
  static const Color navy200 = Color(0xFFB6D2FB);
  static const Color navy100 = Color(0xFFD4F1F7);

  // ── Accent · gold ───────────────────────────────────────
  static const Color gold = Color(0xFFB8895C);
  static const Color goldSoft = Color(0xFFE9D9C2);
  static const Color goldDeep = Color(0xFF8C6235);

  // ── Surfaces ────────────────────────────────────────────
  static const Color paper = Color(0xFFF6F8FB);
  static const Color paper2 = Color(0xFFEEF2F8);
  static const Color paper3 = Color(0xFFE5EBF4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFFBFCFE);

  // ── Lines ───────────────────────────────────────────────
  static const Color hairline = Color(0xFFE2E8F0);
  static const Color hairline2 = Color(0xFFCBD5E1);
  static const Color hairlineStrong = Color(0xFF94A3B8);

  // ── Ink (text) ──────────────────────────────────────────
  static const Color ink900 = Color(0xFF0B1830);
  static const Color ink800 = Color(0xFF162646);
  static const Color ink700 = Color(0xFF27374D);
  static const Color ink500 = Color(0xFF4A5A75);
  static const Color ink300 = Color(0xFF7A8AA5);
  static const Color ink200 = Color(0xFFA6B3C8);

  // ── Status ──────────────────────────────────────────────
  static const Color emerg = Color(0xFFD6243A);
  static const Color emerg2 = Color(0xFFB81B30);
  static const Color emergSoft = Color(0xFFFBE7EA);
  static const Color emergBg = Color(0xFFFFF5F1);
  static const Color emergBorder = Color(0xFFF8D6CB);
  static const Color ok = Color(0xFF2BA374);
  static const Color okSoft = Color(0xFFDDF2E9);
  static const Color warn = Color(0xFFC58B12);
  static const Color warnSoft = Color(0xFFFBEFD3);
  static const Color info = Color(0xFF2E69E7);
  static const Color infoSoft = Color(0xFFDCE7FB);

  // ── Call · VETO Bold dark stage ────────────────────────────
  static const Color callBgTop = Color(0xFF0B1830);
  static const Color callBgBottom = Color(0xFF05101F);
  static const Color callGlass = Color.fromRGBO(11, 24, 48, 0.72);
  static const Color callGlassSoft = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color callGoldHair = Color(0x47B8895C);
  static const Color callGoldHairSoft = Color(0x24B8895C);
  static const Color callDangerRed = Color(0xFFE5354C);
  static const Color callRecBg = Color.fromRGBO(229, 53, 76, 0.18);
  static const Color callStatusGreen = Color(0xFF21C07A);

  // ── Typography ──────────────────────────────────────────
  /// Serif for headings. Flutter ships Frank Ruhl Libre via Google Fonts;
  /// we register it as a bundled family name but also provide a system
  /// fallback so unstyled boots don't crash.
  static const String serif = 'Frank Ruhl Libre';
  static const String sans = 'Heebo';

  // ── Radii ───────────────────────────────────────────────
  static const double rXs = 6;
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 22;
  static const double r2xl = 28;
  static const double rPill = 999;
  static const double callRadiusPanel = 18;
  static const double callRadiusVideo = 20;
  static const double callRadiusPip = 14;
  static const double callRadiusBtn = 999;

  // ── Spacing ─────────────────────────────────────────────
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  // ── Shadows ─────────────────────────────────────────────
  static const List<BoxShadow> shadow1 = [
    BoxShadow(color: Color(0x0A0B1830), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0B1830), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> shadow2 = [
    BoxShadow(color: Color(0x0D0B1830), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A0B1830), blurRadius: 48, offset: Offset(0, 18)),
  ];
  static const List<BoxShadow> shadow3 = [
    BoxShadow(color: Color(0x0F0B1830), blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x240B1830), blurRadius: 72, offset: Offset(0, 28)),
  ];
  static const List<BoxShadow> shadowEmerg = [
    BoxShadow(color: Color(0x47D6243A), blurRadius: 40, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> shadowBrand = [
    BoxShadow(color: Color(0x4C264975), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Primary filled-button gradient (navy ladder).
  static const LinearGradient brandButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy700, navy500],
  );

  // ── Background gradient ────────────────────────────────
  static BoxDecoration pageBackground() => const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.9, -1.1),
          radius: 1.5,
          colors: [Color(0xFFE8F0FB), paper],
          stops: [0.0, 0.6],
        ),
      );
}

/// ════════════════════════════════════════════════════════════
///  V26Backdrop — full-screen light paper page background.
///  Mirrors the `body` radial gradients from `_veto-2026.css`.
/// ════════════════════════════════════════════════════════════
class V26Backdrop extends StatelessWidget {
  final Widget child;
  const V26Backdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: V26.paper),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _V26PageGlowPainter()),
          ),
        ),
        child,
      ],
    );
  }
}

class _V26PageGlowPainter extends CustomPainter {
  const _V26PageGlowPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _blob(canvas, Offset(w * 0.9, -h * 0.1), w * 1.0, const Color(0xFFE8F0FB));
    _blob(canvas, Offset(-w * 0.1, h * 1.1), w * 0.8, const Color(0xFFF0E9DE));
  }

  void _blob(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Light "city" map strip for the lawyer console.
class V26CommandMapPainter extends CustomPainter {
  const V26CommandMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [V26.paper, Color(0xFFE5ECF6)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final grid = Paint()
      ..color = V26.navy600.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (var x = 0.0; x < w; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (var y = 0.0; y < h; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    final route = Paint()
      ..color = V26.navy600.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.35, h * 0.45, w * 0.72, h * 0.55)
      ..quadraticBezierTo(w * 0.9, h * 0.62, w, h * 0.38);
    canvas.drawPath(path, route);

    void pin(Offset c, Color col) {
      canvas.drawCircle(
        c,
        22,
        Paint()
          ..shader = RadialGradient(
            colors: [col.withValues(alpha: 0.30), col.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: 22)),
      );
      canvas.drawCircle(c, 6, Paint()..color = col);
      canvas.drawCircle(
        c,
        9,
        Paint()
          ..color = col.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    pin(Offset(w * 0.22, h * 0.38), V26.navy600);
    pin(Offset(w * 0.55, h * 0.52), V26.gold);
    pin(Offset(w * 0.78, h * 0.32), V26.navy600);
    pin(Offset(w * 0.42, h * 0.72), V26.emerg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class V26CommandMapPanel extends StatelessWidget {
  final double height;
  const V26CommandMapPanel({super.key, this.height = 170});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(V26.rLg),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const CustomPaint(painter: V26CommandMapPainter()),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Card — white card with hairline border + soft shadow.
/// ════════════════════════════════════════════════════════════
class V26Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool lift;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const V26Card({
    super.key,
    required this.child,
    this.padding,
    this.radius = V26.rLg,
    this.lift = false,
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? V26.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? V26.hairline, width: 1),
        boxShadow: lift ? V26.shadow2 : V26.shadow1,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(V26.s4),
        child: child,
      ),
    );
    if (onTap == null) return box;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: box,
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Badge — compact colored tag.
/// ════════════════════════════════════════════════════════════
enum V26BadgeTone { neutral, brand, ok, warn, danger, gold }

class V26Badge extends StatelessWidget {
  final String label;
  final V26BadgeTone tone;
  final IconData? icon;

  const V26Badge(this.label,
      {super.key, this.tone = V26BadgeTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      V26BadgeTone.brand => (
          V26.infoSoft,
          V26.navy700,
          const Color(0xFFC4D4F4)
        ),
      V26BadgeTone.ok => (
          V26.okSoft,
          const Color(0xFF16664B),
          const Color(0xFFB7DFCB)
        ),
      V26BadgeTone.warn => (
          V26.warnSoft,
          const Color(0xFF7A5300),
          const Color(0xFFF2D58E)
        ),
      V26BadgeTone.danger => (
          V26.emergBg,
          const Color(0xFF8E1626),
          V26.emergBorder
        ),
      V26BadgeTone.gold => (
          V26.goldSoft,
          V26.goldDeep,
          const Color(0xFFD4BB99)
        ),
      V26BadgeTone.neutral => (V26.paper2, V26.ink700, V26.hairline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(V26.rPill),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 12),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: V26.sans,
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Kicker — uppercase navy eyebrow text.
/// ════════════════════════════════════════════════════════════
class V26Kicker extends StatelessWidget {
  final String text;
  const V26Kicker(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: V26.sans,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: V26.navy600,
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Headline — serif display headline.
/// ════════════════════════════════════════════════════════════
class V26Headline extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const V26Headline(
    this.text, {
    super.key,
    this.size = 24,
    this.color,
    this.weight = FontWeight.w700,
    this.align,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: V26.serif,
        fontSize: size,
        height: 1.15,
        letterSpacing: -0.3,
        fontWeight: weight,
        color: color ?? V26.ink900,
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26CTA — primary / ghost / subtle / danger / gold button.
/// ════════════════════════════════════════════════════════════
enum V26CtaVariant { primary, ghost, ghostLight, subtle, danger, gold }

class V26CTA extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final V26CtaVariant variant;
  final IconData? icon;
  final bool large;
  final bool expanded;
  final bool loading;

  const V26CTA(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = V26CtaVariant.primary,
    this.icon,
    this.large = false,
    this.expanded = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, shadow) = switch (variant) {
      V26CtaVariant.primary => (
          V26.navy600,
          Colors.white,
          null,
          V26.shadowBrand
        ),
      V26CtaVariant.ghost => (
          V26.surface,
          V26.navy600,
          V26.navy300,
          const <BoxShadow>[]
        ),
      V26CtaVariant.ghostLight => (
          Colors.transparent,
          Colors.white,
          Colors.white.withValues(alpha: 0.45),
          const <BoxShadow>[],
        ),
      V26CtaVariant.subtle => (
          V26.paper2,
          V26.navy700,
          V26.hairline,
          const <BoxShadow>[]
        ),
      V26CtaVariant.danger => (
          V26.emerg,
          Colors.white,
          null,
          const [
            BoxShadow(
                color: Color(0x4CD6243A), blurRadius: 16, offset: Offset(0, 6))
          ]
        ),
      V26CtaVariant.gold => (
          V26.gold,
          Colors.white,
          null,
          const [
            BoxShadow(
                color: Color(0x52B8895C), blurRadius: 16, offset: Offset(0, 6))
          ]
        ),
    };

    final height = large ? 48.0 : 38.0;
    final h = large ? 22.0 : 16.0;
    final r = large ? 12.0 : 10.0;

    Widget btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(r),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(r),
            border: border != null ? Border.all(color: border, width: 1) : null,
            boxShadow: shadow,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: fg,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, color: fg, size: large ? 18 : 16),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: V26.sans,
                    color: fg,
                    fontSize: large ? 14 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (expanded) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }
}

/// ════════════════════════════════════════════════════════════
///  V26StatCard — KPI card (label / value / delta / icon).
/// ════════════════════════════════════════════════════════════
class V26StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final bool deltaDown;
  final IconData? icon;
  final Widget? trailing;

  const V26StatCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaDown = false,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return V26Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: V26.paper2,
                    border: Border.all(color: V26.hairline),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: V26.navy600),
                ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: V26.serif,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: V26.ink900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: V26.ink500,
              letterSpacing: 0.6,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 6),
            Text(
              delta!,
              style: TextStyle(
                fontFamily: V26.sans,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: deltaDown ? V26.emerg : V26.ok,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Status — pill with optional dot.
/// ════════════════════════════════════════════════════════════
enum V26StatusTone { online, busy, offline, live }

class V26Status extends StatelessWidget {
  final String text;
  final V26StatusTone tone;

  const V26Status(this.text, {super.key, this.tone = V26StatusTone.online});

  @override
  Widget build(BuildContext context) {
    final (dotColor, halo) = switch (tone) {
      V26StatusTone.online => (V26.ok, const Color(0x2E2BA374)),
      V26StatusTone.busy => (V26.warn, const Color(0x2EC58B12)),
      V26StatusTone.offline => (V26.ink300, const Color(0x00000000)),
      V26StatusTone.live => (V26.emerg, const Color(0x33D6243A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: V26.surface,
        borderRadius: BorderRadius.circular(V26.rPill),
        border: Border.all(color: V26.hairline),
        boxShadow: V26.shadow1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(color: halo, blurRadius: 0, spreadRadius: 3),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: V26.ink700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26RowItem — clean list row for settings / profile sections.
/// ════════════════════════════════════════════════════════════
class V26RowItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool first;
  final bool last;

  const V26RowItem({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: V26.surface,
        border: Border(
          top: BorderSide(
              color: first ? V26.hairline : Colors.transparent, width: 1),
          left: const BorderSide(color: V26.hairline),
          right: const BorderSide(color: V26.hairline),
          bottom: BorderSide(color: last ? V26.hairline : V26.hairline),
        ),
        borderRadius: BorderRadius.vertical(
          top: first ? const Radius.circular(V26.rMd) : Radius.zero,
          bottom: last ? const Radius.circular(V26.rMd) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: V26.paper2,
                border: Border.all(color: V26.hairline),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child:
                  Icon(icon, size: 16, color: danger ? V26.emerg : V26.navy600),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: danger ? V26.emerg : V26.ink900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: V26.sans,
                      fontSize: 12,
                      color: V26.ink500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 10),
            Text(
              value!,
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: V26.ink700,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded,
                color: V26.ink300, size: 18),
          ],
        ],
      ),
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: first ? const Radius.circular(V26.rMd) : Radius.zero,
        bottom: last ? const Radius.circular(V26.rMd) : Radius.zero,
      ),
      child: body,
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Callout — info / warn / danger / success banner.
/// ════════════════════════════════════════════════════════════
enum V26CalloutTone { info, warn, danger, success }

class V26Callout extends StatelessWidget {
  final String text;
  final V26CalloutTone tone;
  final IconData? icon;

  const V26Callout(this.text,
      {super.key, this.tone = V26CalloutTone.info, this.icon});

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icoBg, icoFg, fallbackIcon) = switch (tone) {
      V26CalloutTone.info => (
          V26.infoSoft,
          const Color(0xFFC4D4F4),
          V26.navy800,
          V26.navy600,
          Colors.white,
          Icons.info_outline_rounded,
        ),
      V26CalloutTone.warn => (
          V26.warnSoft,
          const Color(0xFFF2D58E),
          const Color(0xFF7A5300),
          V26.warn,
          Colors.white,
          Icons.warning_amber_rounded,
        ),
      V26CalloutTone.danger => (
          V26.emergBg,
          V26.emergBorder,
          const Color(0xFF7A2A12),
          const Color(0xFFF4B59C),
          const Color(0xFF5A1F0E),
          Icons.error_outline_rounded,
        ),
      V26CalloutTone.success => (
          V26.okSoft,
          const Color(0xFFB7DFCB),
          const Color(0xFF16664B),
          V26.ok,
          Colors.white,
          Icons.check_circle_outline_rounded,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(V26.s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(V26.rMd),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: icoBg,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(icon ?? fallbackIcon, size: 14, color: icoFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: V26.sans,
                fontSize: 13,
                height: 1.55,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Crest — serif brand crest ("V").
/// ════════════════════════════════════════════════════════════
class V26Crest extends StatelessWidget {
  final double size;
  final String letter;
  const V26Crest({super.key, this.size = 34, this.letter = 'V'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [V26.navy700, V26.navy500],
        ),
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: const [
          BoxShadow(
              color: Color(0x59264975), blurRadius: 14, offset: Offset(0, 6)),
        ],
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: V26.serif,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontSize: size * 0.44,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26BrandLogo — crest + name + optional eyebrow.
/// ════════════════════════════════════════════════════════════
class V26BrandLogo extends StatelessWidget {
  final String name;
  final String? eyebrow;
  final double size;
  final Color nameColor;
  final Color eyebrowColor;

  const V26BrandLogo({
    super.key,
    this.name = 'VETO',
    this.eyebrow,
    this.size = 34,
    this.nameColor = V26.ink900,
    this.eyebrowColor = V26.navy600,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        V26Crest(size: size),
        const SizedBox(width: 10),
        Text(
          name,
          style: TextStyle(
            fontFamily: V26.serif,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: nameColor,
            letterSpacing: 0.4,
          ),
        ),
        if (eyebrow != null) ...[
          const SizedBox(width: 6),
          Text(
            eyebrow!.toUpperCase(),
            style: TextStyle(
              fontFamily: V26.sans,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: eyebrowColor,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Topbar — desktop-style header bar (brand + nav + actions).
/// ════════════════════════════════════════════════════════════
class V26Topbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget leading;
  final List<Widget> actions;
  final double height;
  final EdgeInsets padding;

  const V26Topbar({
    super.key,
    required this.leading,
    this.actions = const [],
    this.height = 64,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: const BoxDecoration(
        color: V26.surface,
        border: Border(bottom: BorderSide(color: V26.hairline)),
      ),
      child: Row(
        children: [
          leading,
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26IconBtn — 38×38 outlined icon button.
/// ════════════════════════════════════════════════════════════
class V26IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool small;

  const V26IconBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 32.0 : 38.0;
    final r = small ? 8.0 : 10.0;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: V26.surface,
            border: Border.all(color: V26.hairline),
            borderRadius: BorderRadius.circular(r),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: small ? 14 : 16, color: V26.ink700),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Sidebar — desktop vertical navigation column.
/// ════════════════════════════════════════════════════════════
class V26SidebarItem {
  final String label;
  final IconData icon;
  final int? count;
  final bool active;
  final VoidCallback? onTap;
  const V26SidebarItem({
    required this.label,
    required this.icon,
    this.count,
    this.active = false,
    this.onTap,
  });
}

class V26SidebarGroup {
  final String? title;
  final List<V26SidebarItem> items;
  const V26SidebarGroup({this.title, required this.items});
}

class V26Sidebar extends StatelessWidget {
  final Widget? header;
  final List<V26SidebarGroup> groups;
  final Widget? footer;
  final double width;
  final String? activeLabel;
  /// Burgundy active state + mockup card surface (lawyer dashboard parity).
  final bool useMockupTokens;

  const V26Sidebar({
    super.key,
    this.header,
    required this.groups,
    this.footer,
    this.width = 240,
    this.activeLabel,
    this.useMockupTokens = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: useMockupTokens ? VetoMockup.surfaceCard : V26.surface,
        border: Border(
          right: BorderSide(
            color: useMockupTokens ? VetoMockup.hairline : V26.hairline,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 18),
              child: header!,
            ),
            Container(
                height: 1,
                color: useMockupTokens ? VetoMockup.hairline : V26.hairline),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final g in groups) ...[
                  if (g.title != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                      child: Text(
                        g.title!.toUpperCase(),
                        style: TextStyle(
                          fontFamily: V26.sans,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: useMockupTokens
                              ? VetoMockup.inkSecondary
                              : V26.ink300,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  for (final item in g.items)
                    _SidebarEntry(
                      item: item,
                      useMockupTokens: useMockupTokens,
                      active: item.active ||
                          (activeLabel != null && activeLabel == item.label),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null) ...[
            Container(
                height: 1,
                color: useMockupTokens ? VetoMockup.hairline : V26.hairline),
            Padding(
              padding: const EdgeInsets.all(10),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarEntry extends StatelessWidget {
  final V26SidebarItem item;
  final bool active;
  final bool useMockupTokens;
  const _SidebarEntry({
    required this.item,
    required this.active,
    this.useMockupTokens = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeBg = useMockupTokens
        ? VetoMockup.primaryCta.withValues(alpha: 0.08)
        : V26.navy100;
    final Color activeFg =
        useMockupTokens ? VetoMockup.primaryCtaDeep : V26.navy700;
    final Color idleFg =
        useMockupTokens ? VetoMockup.ink : V26.ink700;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: active ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: useMockupTokens && active
                  ? const Border(
                      right: BorderSide(
                        color: VetoMockup.primaryCta,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 16, color: active ? activeFg : idleFg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: V26.sans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? activeFg : idleFg,
                    ),
                  ),
                ),
                if (item.count != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: useMockupTokens
                          ? (active
                              ? VetoMockup.primaryCta.withValues(alpha: 0.12)
                              : VetoMockup.pageBackground)
                          : (active ? V26.navy200 : V26.paper2),
                      borderRadius: BorderRadius.circular(V26.rPill),
                    ),
                    child: Text(
                      item.count.toString(),
                      style: TextStyle(
                        fontFamily: V26.sans,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: useMockupTokens
                            ? (active
                                ? VetoMockup.primaryCtaDeep
                                : VetoMockup.inkSecondary)
                            : (active ? V26.navy700 : V26.ink300),
                      ),
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

/// ════════════════════════════════════════════════════════════
///  V26Avatar — serif initials inside rounded square.
/// ════════════════════════════════════════════════════════════
enum V26AvatarSize { sm, md, lg, xl }

class V26Avatar extends StatelessWidget {
  final String initials;
  final V26AvatarSize size;
  final bool gold;

  const V26Avatar(this.initials,
      {super.key, this.size = V26AvatarSize.md, this.gold = false});

  @override
  Widget build(BuildContext context) {
    final (w, r, fs) = switch (size) {
      V26AvatarSize.sm => (30.0, 8.0, 12.0),
      V26AvatarSize.md => (46.0, 14.0, 16.0),
      V26AvatarSize.lg => (64.0, 18.0, 22.0),
      V26AvatarSize.xl => (96.0, 24.0, 34.0),
    };
    return Container(
      width: w,
      height: w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gold
              ? const [V26.goldSoft, V26.gold]
              : const [V26.navy300, V26.navy500],
        ),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: V26.serif,
          color: Colors.white,
          fontSize: fs,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Dot — presence dot (online/busy/offline/live).
/// ════════════════════════════════════════════════════════════
class V26Dot extends StatelessWidget {
  final V26StatusTone tone;
  final double size;

  const V26Dot({super.key, this.tone = V26StatusTone.online, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      V26StatusTone.online => V26.ok,
      V26StatusTone.busy => V26.warn,
      V26StatusTone.offline => V26.ink300,
      V26StatusTone.live => V26.emerg,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: tone == V26StatusTone.offline
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26DarkRail — dark rail used by wizard/login side columns.
/// ════════════════════════════════════════════════════════════
class V26DarkRail extends StatelessWidget {
  final Widget child;
  final double? width;

  const V26DarkRail({super.key, required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [V26.ink900, V26.navy800],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _RailGlowPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RailGlowPainter extends CustomPainter {
  const _RailGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w, 0);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFB8895C).withValues(alpha: 0.20),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: w * 0.8));
    canvas.drawCircle(c, w * 0.8, paint);

    final c2 = Offset(-w * 0.2, h);
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2E69E7).withValues(alpha: 0.12),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: c2, radius: w * 0.8));
    canvas.drawCircle(c2, w * 0.8, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ════════════════════════════════════════════════════════════
///  V26SOSOrb — radial SOS emergency orb.
/// ════════════════════════════════════════════════════════════
class V26SOSOrb extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final String text;

  const V26SOSOrb({
    super.key,
    this.size = 180,
    this.onTap,
    this.text = 'SOS',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.4, -0.5),
              radius: 1.2,
              colors: [
                Color(0xFFFF8492),
                Color(0xFFE5354C),
                Color(0xFFB81B30),
              ],
              stops: [0.0, 0.38, 0.78],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x47D6243A),
                blurRadius: 40,
                offset: Offset(0, 12),
              ),
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 24,
                offset: Offset(0, -10),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Specular highlight
              Padding(
                padding: EdgeInsets.all(size * 0.04),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.7),
                      radius: 0.5,
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: V26.serif,
                    color: Colors.white,
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: size * 0.01,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Section — titled group with kicker and children.
/// ════════════════════════════════════════════════════════════
class V26Section extends StatelessWidget {
  final String? kicker;
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const V26Section({
    super.key,
    this.kicker,
    this.title,
    this.subtitle,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kicker != null) ...[
            V26Kicker(kicker!),
            const SizedBox(height: 6),
          ],
          if (title != null)
            V26Headline(title!, size: 22, weight: FontWeight.w800),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 13,
                color: V26.ink500,
                height: 1.5,
              ),
            ),
          ],
          if (kicker != null || title != null || subtitle != null)
            const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  VetoBreakpoint — responsive tier (mobile / tablet / desktop).
/// ════════════════════════════════════════════════════════════
enum VetoBreakpoint { mobile, tablet, desktop }

extension VetoBreakpointContext on BuildContext {
  // Single breakpoint at 900px per the VETO 2026 spec: phones/small-tablets use
  // the mobile layout (bottom nav, FAB, sheets), anything wider gets the
  // desktop layout (sidebar, split-view, wide tables). The `tablet` value is
  // kept in the enum for backwards compatibility but is no longer returned.
  VetoBreakpoint get vetoBreakpoint {
    final w = MediaQuery.sizeOf(this).width;
    if (w < 900) return VetoBreakpoint.mobile;
    return VetoBreakpoint.desktop;
  }

  bool get isMobile => vetoBreakpoint == VetoBreakpoint.mobile;
  bool get isTablet => vetoBreakpoint == VetoBreakpoint.tablet;
  bool get isDesktop => vetoBreakpoint == VetoBreakpoint.desktop;
  bool get isCompact => vetoBreakpoint != VetoBreakpoint.desktop;
}

/// ════════════════════════════════════════════════════════════
///  V26PageHeader — mirror of `.page-header` in _veto-2026.css.
/// ════════════════════════════════════════════════════════════
class V26PageHeader extends StatelessWidget {
  final String title;
  final String? tag;
  final String? subtitle;
  final List<Widget> actions;
  final double? titleSize;

  const V26PageHeader({
    super.key,
    required this.title,
    this.tag,
    this.subtitle,
    this.actions = const [],
    this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            V26Headline(title,
                size: titleSize ?? (context.isDesktop ? 34 : 26),
                weight: FontWeight.w800),
            if (tag != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: V26.surface,
                  borderRadius: BorderRadius.circular(V26.rPill),
                  border: Border.all(color: V26.hairline),
                ),
                child: Text(
                  tag!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: V26.navy600,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            if (actions.isNotEmpty) ...actions,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              subtitle!,
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 15,
                color: V26.ink500,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26NavItem — nav definition shared by sidebar + bottom nav.
/// ════════════════════════════════════════════════════════════
class V26NavItem {
  final String label;
  final IconData icon;
  final String? route;
  final int? count;
  final VoidCallback? onTap;
  const V26NavItem({
    required this.label,
    required this.icon,
    this.route,
    this.count,
    this.onTap,
  });
}

/// ════════════════════════════════════════════════════════════
///  V26BottomNav — mobile bottom tab bar.
///  Mirrors `.tabbar` in _veto-2026.css.
/// ════════════════════════════════════════════════════════════
class V26BottomNav extends StatelessWidget {
  final List<V26NavItem> items;
  final int currentIndex;
  final ValueChanged<int>? onChanged;

  const V26BottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomSafe),
      decoration: const BoxDecoration(
        color: V26.surface,
        border: Border(top: BorderSide(color: V26.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = i == currentIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (item.onTap != null) {
                        item.onTap!();
                      } else {
                        onChanged?.call(i);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: active ? V26.navy600 : V26.ink300,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: V26.sans,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: active ? V26.navy600 : V26.ink300,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            width: active ? 22 : 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: active ? V26.navy600 : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Tabs — segmented pill tabs (mirror of `.tabs` in CSS).
/// ════════════════════════════════════════════════════════════
class V26Tabs extends StatelessWidget {
  final List<String> labels;
  final int current;
  final ValueChanged<int>? onChanged;

  const V26Tabs({
    super.key,
    required this.labels,
    required this.current,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: V26.paper2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: V26.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final active = i == current;
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: () => onChanged?.call(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? V26.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: active ? V26.shadow1 : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: V26.sans,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? V26.navy700 : V26.ink500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  VetoRole — app role identity (affects sidebar + accents).
/// ════════════════════════════════════════════════════════════
enum VetoRole { citizen, lawyer, admin, guest }

/// ════════════════════════════════════════════════════════════
///  VetoScaffold — unified responsive scaffold (mobile / desktop).
///  - Mobile: appbar (optional) + body + bottom nav.
///  - Desktop: sidebar + body (+ optional top bar).
/// ════════════════════════════════════════════════════════════
class VetoScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final List<V26NavItem>? navItems;
  final int currentNavIndex;
  final ValueChanged<int>? onNavChanged;
  final V26Sidebar? sidebar;
  final Widget? desktopTopBar;
  final Widget? floatingAction;
  final bool backdrop;
  final Color? background;
  final bool extendBehindAppBar;

  const VetoScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.navItems,
    this.currentNavIndex = 0,
    this.onNavChanged,
    this.sidebar,
    this.desktopTopBar,
    this.floatingAction,
    this.backdrop = true,
    this.background,
    this.extendBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    Widget content = body;

    // Desktop layout: sidebar + content column
    if (isDesktop && sidebar != null) {
      content = Row(
        children: [
          sidebar!,
          Expanded(
            child: Column(
              children: [
                if (desktopTopBar != null) desktopTopBar!,
                Expanded(child: body),
              ],
            ),
          ),
        ],
      );
    } else if (isDesktop && desktopTopBar != null) {
      content = Column(
        children: [
          desktopTopBar!,
          Expanded(child: body),
        ],
      );
    }

    final scaffold = Scaffold(
      backgroundColor:
          background ?? (backdrop ? Colors.transparent : V26.paper),
      extendBodyBehindAppBar: extendBehindAppBar,
      appBar: isDesktop ? null : appBar,
      body: content,
      bottomNavigationBar:
          (!isDesktop && navItems != null && navItems!.isNotEmpty)
              ? V26BottomNav(
                  items: navItems!,
                  currentIndex: currentNavIndex,
                  onChanged: onNavChanged,
                )
              : null,
      floatingActionButton: floatingAction,
    );

    if (!backdrop) return scaffold;
    return V26Backdrop(child: scaffold);
  }
}

/// ════════════════════════════════════════════════════════════
///  V26DarkSurface — dark page surface (used by voice / video call).
///  Mirrors the rare dark panels in _veto-2026.css (call screens).
/// ════════════════════════════════════════════════════════════
class V26DarkSurface extends StatelessWidget {
  final Widget child;
  final bool withGlow;

  const V26DarkSurface({super.key, required this.child, this.withGlow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [V26.ink900, V26.navy900],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (withGlow)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _RailGlowPainter()),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26PulseDots — 3 pulsing dots (SOS / call-entry / splash loading).
/// ════════════════════════════════════════════════════════════
class V26PulseDots extends StatefulWidget {
  final Color color;
  final double size;
  const V26PulseDots({
    super.key,
    this.color = V26.navy500,
    this.size = 10,
  });

  @override
  State<V26PulseDots> createState() => _V26PulseDotsState();
}

class _V26PulseDotsState extends State<V26PulseDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value - i * 0.18) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            final opacity = 0.35 + 0.65 * scale;
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: widget.size * scale,
                  height: widget.size * scale,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26FieldLabel / V26TextField — matches `.field` in CSS.
/// ════════════════════════════════════════════════════════════
class V26Field extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? help;
  final String? errorText;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final String? initialValue;
  final FocusNode? focusNode;

  const V26Field({
    super.key,
    this.label,
    this.hint,
    this.help,
    this.errorText,
    this.icon,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.initialValue,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: V26.ink700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: V26.sans,
            fontSize: 14,
            color: V26.ink900,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: V26.surface,
            hintText: hint,
            hintStyle: const TextStyle(color: V26.ink300, fontFamily: V26.sans),
            suffixIcon:
                icon != null ? Icon(icon, color: V26.ink300, size: 18) : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 12 : 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: V26.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: V26.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: V26.navy500, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: V26.emerg),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: V26.emerg,
            ),
          ),
        ),
        if (help != null && errorText == null) ...[
          const SizedBox(height: 4),
          Text(
            help!,
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 11,
              color: V26.ink500,
            ),
          ),
        ],
      ],
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Progress — progress bar (matches `.progress` in CSS).
/// ════════════════════════════════════════════════════════════
class V26Progress extends StatelessWidget {
  final double value;
  final double height;

  const V26Progress({super.key, required this.value, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: V26.paper2,
        borderRadius: BorderRadius.circular(V26.rPill),
        border: Border.all(color: V26.hairline),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [V26.navy500, V26.navy600],
              ),
              borderRadius: BorderRadius.circular(V26.rPill),
            ),
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Empty — empty state (mirror `.empty` in CSS).
/// ════════════════════════════════════════════════════════════
class V26Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const V26Empty({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(V26.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: V26.paper2,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 30, color: V26.navy600),
            ),
            const SizedBox(height: 14),
            V26Headline(title, size: 18, weight: FontWeight.w800),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 14,
                  color: V26.ink500,
                  height: 1.55,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Stepper — vertical step list (wizard / login dark rail).
/// ════════════════════════════════════════════════════════════
class V26StepperStep {
  final String title;
  final String? caption;
  const V26StepperStep({required this.title, this.caption});
}

class V26Stepper extends StatelessWidget {
  final List<V26StepperStep> steps;
  final int current;
  final bool onDark;

  const V26Stepper({
    super.key,
    required this.steps,
    required this.current,
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final done = i < current;
        final active = i == current;
        final isLast = i == steps.length - 1;
        final Color markerBg = done
            ? V26.navy500
            : active
                ? Colors.white
                : (onDark ? Colors.white.withValues(alpha: 0.12) : V26.paper2);
        final Color markerFg = done
            ? Colors.white
            : active
                ? V26.navy700
                : (onDark ? Colors.white.withValues(alpha: 0.6) : V26.ink500);
        final Color titleColor = onDark
            ? (active || done
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7))
            : (active || done ? V26.ink900 : V26.ink500);
        final Color captionColor =
            onDark ? Colors.white.withValues(alpha: 0.55) : V26.ink300;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: markerBg,
                      shape: BoxShape.circle,
                      border: onDark && !done && !active
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            )
                          : null,
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontFamily: V26.serif,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: markerFg,
                            ),
                          ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: done
                          ? V26.navy400.withValues(alpha: 0.7)
                          : onDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : V26.hairline,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: V26.serif,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.25,
                        ),
                      ),
                      if (step.caption != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          step.caption!,
                          style: TextStyle(
                            fontFamily: V26.sans,
                            fontSize: 12,
                            color: captionColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26Table — admin table wrapper (mirror `.tbl` in CSS).
/// ════════════════════════════════════════════════════════════
class V26TableColumn {
  final String label;
  final double? width;
  final TextAlign align;
  const V26TableColumn(this.label, {this.width, this.align = TextAlign.start});
}

class V26Table extends StatelessWidget {
  final List<V26TableColumn> columns;
  final List<List<Widget>> rows;

  const V26Table({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return V26Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: const BoxDecoration(
              color: V26.surface2,
              border: Border(bottom: BorderSide(color: V26.hairline)),
            ),
            child: Row(
              children: [
                for (int ci = 0; ci < columns.length; ci++)
                  ci == columns.length - 1
                      ? Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              columns[ci].label.toUpperCase(),
                              textAlign: columns[ci].align,
                              style: const TextStyle(
                                fontFamily: V26.sans,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: V26.ink500,
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: columns[ci].width,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              columns[ci].label.toUpperCase(),
                              textAlign: columns[ci].align,
                              style: const TextStyle(
                                fontFamily: V26.sans,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: V26.ink500,
                              ),
                            ),
                          ),
                        ),
              ],
            ),
          ),
          for (int r = 0; r < rows.length; r++)
            Container(
              decoration: BoxDecoration(
                border: r == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: V26.hairline),
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (int ci = 0; ci < rows[r].length; ci++)
                    ci == rows[r].length - 1
                        ? Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: rows[r][ci],
                            ),
                          )
                        : SizedBox(
                            width:
                                ci < columns.length ? columns[ci].width : null,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: rows[r][ci],
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

/// ════════════════════════════════════════════════════════════
///  V26NavDest — one destination in the 2026 app shell.
///  Mirrors `<a class="nav">...` from `2026/citizen.html:726-733`.
/// ════════════════════════════════════════════════════════════
class V26NavDest {
  final String label;
  final IconData icon;
  final int? badge;
  const V26NavDest({
    required this.label,
    required this.icon,
    this.badge,
  });
}

/// ════════════════════════════════════════════════════════════
///  V26DesktopNavBar — top pill-nav for wide viewports.
///  Mirrors `.topbar + .nav` from `2026/citizen.html`.
///  Pass [currentIndex] = -1 for routes that aren't in the main
///  nav (e.g. `/settings`, `/profile`) so no pill is highlighted.
/// ════════════════════════════════════════════════════════════
class V26DesktopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final List<V26NavDest> destinations;

  /// Index of the active nav item. Use `-1` when none should be highlighted.
  final int currentIndex;
  final ValueChanged<int>? onSelected;
  final Widget? brand;
  final List<Widget> trailing;
  final String? statusText;

  const V26DesktopNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    this.onSelected,
    this.brand,
    this.trailing = const [],
    this.statusText,
  });

  @override
  Size get preferredSize => Size.fromHeight(statusText != null ? 112 : 72);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: V26.surface,
        border: Border(bottom: BorderSide(color: V26.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  brand ?? const V26BrandLogo(eyebrow: 'הגנה משפטית מיידית'),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        for (int i = 0; i < destinations.length; i++)
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                                end: i < destinations.length - 1 ? 4 : 0),
                            child: _V26DesktopNavLink(
                              dest: destinations[i],
                              active: i == currentIndex,
                              onTap: () => onSelected?.call(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...trailing,
                ],
              ),
            ),
          ),
          if (statusText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: V26.surface2,
                border: Border(top: BorderSide(color: V26.hairline)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: V26.ok,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText!,
                    style: const TextStyle(
                      fontFamily: V26.sans,
                      fontSize: 12,
                      color: V26.ink500,
                      fontWeight: FontWeight.w600,
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

class _V26DesktopNavLink extends StatelessWidget {
  final V26NavDest dest;
  final bool active;
  final VoidCallback? onTap;
  const _V26DesktopNavLink({
    required this.dest,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dest.label,
                style: TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? V26.navy600 : V26.ink700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: active ? 24 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: V26.navy600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26AppShell — unified responsive shell for every screen.
///   - Wide (>=1080px): top pill-nav + optional status strip (citizen.html).
///   - Narrow:         AppBar (optional) + bottom tab bar (legacy mobile).
/// ════════════════════════════════════════════════════════════
class V26AppShell extends StatelessWidget {
  final List<V26NavDest> destinations;
  final int currentIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget child;
  final PreferredSizeWidget? mobileAppBar;
  final String? desktopStatusText;
  final List<Widget> desktopTrailing;
  final Widget? floatingAction;
  final Color? background;
  final bool showBackdrop;
  final Widget? desktopBrand;

  const V26AppShell({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.child,
    this.onDestinationSelected,
    this.mobileAppBar,
    this.desktopStatusText,
    this.desktopTrailing = const [],
    this.floatingAction,
    this.background,
    this.showBackdrop = true,
    this.desktopBrand,
  });

  static const double desktopBreakpoint = 1080;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= desktopBreakpoint;

    final Widget scaffold = Scaffold(
      backgroundColor:
          background ?? (showBackdrop ? Colors.transparent : V26.paper),
      appBar: isWide
          ? V26DesktopNavBar(
              destinations: destinations,
              currentIndex: currentIndex,
              onSelected: onDestinationSelected,
              statusText: desktopStatusText,
              trailing: desktopTrailing,
              brand: desktopBrand,
            )
          : mobileAppBar,
      body: child,
      bottomNavigationBar: isWide
          ? null
          : V26BottomNav(
              items: destinations
                  .map((d) => V26NavItem(
                        label: d.label,
                        icon: d.icon,
                        count: d.badge,
                      ))
                  .toList(),
              currentIndex: currentIndex,
              onChanged: onDestinationSelected,
            ),
      floatingActionButton: floatingAction,
    );

    if (!showBackdrop) return scaffold;
    return V26Backdrop(child: scaffold);
  }
}

/// ════════════════════════════════════════════════════════════
///  V26LangPill — the small flag+language toggle seen in 2026/*.
/// ════════════════════════════════════════════════════════════
class V26LangPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const V26LangPill({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(V26.rPill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: V26.surface,
            border: Border.all(color: V26.hairline),
            borderRadius: BorderRadius.circular(V26.rPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 10,
                decoration: BoxDecoration(
                  color: V26.navy100,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: V26.navy300),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: V26.ink700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26PillCTA — compact pill call-to-action matching .cta in 2026/*.
/// ════════════════════════════════════════════════════════════
class V26PillCTA extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool danger;
  final bool ghost;

  const V26PillCTA({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.danger = false,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color? borderColor;
    final List<BoxShadow> shadow;
    if (ghost) {
      bg = V26.surface;
      fg = V26.navy700;
      borderColor = V26.hairline;
      shadow = const [];
    } else if (danger) {
      bg = V26.emerg;
      fg = Colors.white;
      borderColor = null;
      shadow = V26.shadowEmerg;
    } else {
      bg = V26.navy600;
      fg = Colors.white;
      borderColor = null;
      shadow = V26.shadowBrand;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(V26.rPill),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(V26.rPill),
            border: borderColor != null ? Border.all(color: borderColor) : null,
            boxShadow: shadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════
///  V26CitizenNav — the 6 desktop nav destinations for citizens.
///  Mirrors `<nav class="nav">` from `2026/citizen.html:726-733`.
///  Screens use the same list so the active index stays consistent.
/// ════════════════════════════════════════════════════════════
class V26CitizenNav {
  V26CitizenNav._();

  /// Route names (must match `main.dart` routes).
  static const List<String> routes = <String>[
    '/veto_screen',
    '/chat',
    '/files_vault',
    '/legal_calendar',
    '/legal_notebook',
    '/maps',
  ];

  /// Build the 6 nav destinations for the current locale.
  static List<V26NavDest> destinations(String langCode) {
    final he = langCode == 'he';
    final ru = langCode == 'ru';
    return [
      V26NavDest(
        label: he ? 'דף הבית' : (ru ? 'Главная' : 'Home'),
        icon: Icons.home_rounded,
      ),
      V26NavDest(
        label: he ? 'צ\'אט AI' : (ru ? 'AI-чат' : 'AI Chat'),
        icon: Icons.chat_bubble_rounded,
      ),
      V26NavDest(
        label: he ? 'כספת מסמכים' : (ru ? 'Хранилище' : 'Vault'),
        icon: Icons.lock_rounded,
      ),
      V26NavDest(
        label: he ? 'יומן משפטי' : (ru ? 'Юр. календарь' : 'Calendar'),
        icon: Icons.event_note_rounded,
      ),
      V26NavDest(
        label: he ? 'מחברת' : (ru ? 'Блокнот' : 'Notebook'),
        icon: Icons.edit_note_rounded,
      ),
      V26NavDest(
        label: he ? 'מפה' : (ru ? 'Карта' : 'Map'),
        icon: Icons.map_rounded,
      ),
    ];
  }

  /// The 5 bottom-tab destinations for narrow viewports (citizen bottom bar).
  /// Map is kept accessible on phones to match `2026/vault.html:371-404`.
  static List<V26NavDest> bottomDestinations(String langCode) {
    final he = langCode == 'he';
    final ru = langCode == 'ru';
    return [
      V26NavDest(
        label: he ? 'בית' : (ru ? 'Главная' : 'Home'),
        icon: Icons.home_rounded,
      ),
      V26NavDest(
        label: he ? 'צ\'אט' : (ru ? 'Чат' : 'Chat'),
        icon: Icons.chat_bubble_rounded,
      ),
      V26NavDest(
        label: he ? 'קבצים' : (ru ? 'Файлы' : 'Files'),
        icon: Icons.folder_rounded,
      ),
      V26NavDest(
        label: he ? 'מפה' : (ru ? 'Карта' : 'Map'),
        icon: Icons.map_rounded,
      ),
      V26NavDest(
        label: he ? 'פרופיל' : (ru ? 'Профиль' : 'Profile'),
        icon: Icons.person_rounded,
      ),
    ];
  }

  /// Routes for the bottom 5 tabs, in the same order as [bottomDestinations].
  static const List<String> bottomRoutes = <String>[
    '/veto_screen',
    '/chat',
    '/files_vault',
    '/maps',
    '/profile',
  ];

  /// Navigate to one of the [routes] (or [bottomRoutes]) from [current].
  /// Uses `pushReplacementNamed` so we don't stack identical shells.
  static void go(BuildContext context, String target, {String? current}) {
    if (target == current) return;
    Navigator.of(context).pushReplacementNamed(target);
  }
}
