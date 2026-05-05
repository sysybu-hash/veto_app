// ═══════════════════════════════════════════════════════════════════
//  VETO Landing — 2026 Pango-class marketing
//  Blue primary, light surfaces, drawer + service hub + line-art hero
// ═══════════════════════════════════════════════════════════════════

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../core/theme/veto_2026_splash.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';
import '../widgets/accessibility_toolbar.dart';
import '../widgets/ai_chat_dialog.dart';
import '../widgets/veto_landing_service_hub.dart';
import '../widgets/veto_line_art_painter.dart';
import '../widgets/veto_marketing_drawer.dart';

// ── Palette — 2026 Navy / Gold / Paper ─────────────────────────────
class _C {
  static const bg = VetoMockup.pageBackground;
  static const navBg = V26.surface;
  static const inkDark = V26.ink900;
  static const inkMid = V26.ink700;
  static const inkLight = V26.ink500;
  static const accent = VetoMockup.primaryCta;
}

// ══════════════════════════════════════════════════════════════════
//  ROOT WIDGET
// ══════════════════════════════════════════════════════════════════
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _goNext(BuildContext context) async {
    final auth = AuthService();
    final token = await auth.getToken();
    if (!context.mounted) return;
    if (token != null && token.isNotEmpty) {
      final role = await auth.getStoredRole() ?? 'user';
      if (!context.mounted) return;
      if (role == 'lawyer') {
        Navigator.pushNamed(context, '/lawyer_dashboard');
      } else if (role == 'admin') {
        Navigator.pushNamed(context, '/admin_settings');
      } else {
        final onboarded = await auth.getOnboarded();
        if (!context.mounted) return;
        Navigator.pushNamed(
          context,
          onboarded ? '/veto_screen' : '/wizard_home',
        );
      }
      return;
    }
    Navigator.pushNamed(context, '/login');
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final l10n = AppLocalizations.of(context)!;
    final dir = AppLanguage.directionOf(code);
    final w = MediaQuery.sizeOf(context).width;
    final compact = w < V26AppShell.desktopBreakpoint;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _C.bg,
        endDrawer: VetoMarketingDrawer(l10n: l10n),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'landing_a11y',
              backgroundColor: Colors.white,
              foregroundColor: VetoMockup.primaryCta,
              tooltip: l10n.fabAccessibility,
              onPressed: () => showAccessibilitySheet(context),
              child: const Icon(Icons.accessibility_new_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.small(
              heroTag: 'landing_support',
              backgroundColor: Colors.white,
              foregroundColor: VetoMockup.primaryCta,
              tooltip: l10n.fabCustomerSupport,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.menuContact)),
                );
              },
              child: const Icon(Icons.support_agent_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'landing_ai',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AiChatDialog(code: code),
              ),
              backgroundColor: VetoMockup.primaryCta,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                l10n.fabAskAi,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: V26Backdrop(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavBar(
                  l10n: l10n,
                  code: code,
                  compact: compact,
                  onTap: () => _goNext(context),
                  onOpenDrawer: _openDrawer,
                ),
                _HeroSection(
                  l10n: l10n,
                  compact: compact,
                  onTap: () => _goNext(context),
                ),
                VetoLandingServiceHub(
                  l10n: l10n,
                  compact: compact,
                  onSos: () => _goNext(context),
                ),
                _FeaturesSection(l10n: l10n, compact: compact),
                _StatsBar(l10n: l10n, compact: compact),
                _StackSection(l10n: l10n, compact: compact),
                _PricingSection(
                  l10n: l10n,
                  compact: compact,
                  onTap: () => _goNext(context),
                ),
                _CtaSection(
                  l10n: l10n,
                  compact: compact,
                  onTap: () => _goNext(context),
                ),
                _Footer(l10n: l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  NAV BAR — white frosted, logo right, links + buttons left
// ══════════════════════════════════════════════════════════════════
class _NavBar extends StatefulWidget {
  final AppLocalizations l10n;
  final String code;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onOpenDrawer;
  const _NavBar({
    required this.l10n,
    required this.code,
    required this.compact,
    required this.onTap,
    required this.onOpenDrawer,
  });

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> {
  bool _loggedIn = false;
  String? _role;
  String? _name;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = AuthService();
    final t = await auth.getToken();
    if (t != null && t.isNotEmpty) {
      final r = await auth.getStoredRole();
      final n = await auth.getStoredName();
      if (mounted) {
        setState(() {
          _loggedIn = true;
          _role = r;
          _name = n;
        });
      }
    }
  }

  Future<void> _enterApp(BuildContext ctx) async {
    if (_role == 'lawyer') {
      Navigator.pushNamed(ctx, '/lawyer_dashboard');
    } else if (_role == 'admin') {
      Navigator.pushNamed(ctx, '/admin_settings');
    } else {
      final onboarded = await AuthService().getOnboarded();
      if (!ctx.mounted) return;
      Navigator.pushNamed(
        ctx,
        onboarded ? '/veto_screen' : '/wizard_home',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l10n;
    final navItems = <String>[
      l.navHome,
      l.navFeatures,
      l.navPricing,
      l.navHow,
      l.navContact,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _C.navBg,
        border: Border(bottom: BorderSide(color: V26.hairline)),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 16 : 28, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            children: [
              // ── Logo ──
              Row(mainAxisSize: MainAxisSize.min, children: [
                const V26Crest(size: 34),
                const SizedBox(width: 10),
                const Text(
                  'VETO',
                  style: TextStyle(
                    fontFamily: V26.serif,
                    color: _C.inkDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.compact ? 'LEGAL' : l.brandEyebrow,
                  style: TextStyle(
                    fontFamily: V26.sans,
                    color: VetoMockup.primaryCta,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: widget.compact ? 1.6 : 0,
                  ),
                ),
              ]),

              // ── Nav links (desktop) ──
              if (!widget.compact) ...[
                const SizedBox(width: 32),
                ...navItems.map((item) => TextButton(
                      onPressed: widget.onTap,
                      style: TextButton.styleFrom(
                        foregroundColor: _C.inkMid,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      child: Text(item),
                    )),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: widget.onOpenDrawer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VetoMockup.primaryCta,
                    side: BorderSide(
                      color: VetoMockup.primaryCta.withValues(alpha: 0.35),
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    l.navMenu,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // ── Desktop: language then accessibility (keeps a11y off the outer edge in RTL Web)
              if (!widget.compact) const AppLanguageMenu(compact: true),
              // ── Mobile: hamburger then accessibility (ליד כפתור התפריט), then language
              if (widget.compact)
                IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      color: _C.inkMid, size: 22),
                  onPressed: widget.onOpenDrawer,
                  tooltip: kIsWeb ? null : l.navMenu,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              IconButton(
                icon: Icon(
                  Icons.accessibility_new_rounded,
                  color: _C.inkMid,
                  size: 20,
                  semanticLabel: kIsWeb ? null : l.fabAccessibility,
                ),
                onPressed: () => showAccessibilitySheet(context),
                tooltip: kIsWeb ? null : l.fabAccessibility,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              if (widget.compact) const AppLanguageMenu(compact: true),
              const SizedBox(width: 8),

              // ── Auth: user bubble or login buttons ──
              if (_loggedIn) ...[
                TextButton(
                  onPressed: () => unawaited(_enterApp(context)),
                  child: Text(
                    l.navPersonalArea,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: VetoMockup.primaryCta,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _UserBubble(
                  name: _name,
                  role: _role,
                  l10n: l,
                  onEnterApp: () {
                    unawaited(_enterApp(context));
                  },
                ),
              ] else ...[
                _NavBtn(
                    label: l.navLogin,
                    filled: false,
                    onTap: widget.onTap),
                const SizedBox(width: 8),
                _NavBtn(
                    label: l.navRegister,
                    filled: true,
                    onTap: widget.onTap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _NavBtn(
      {required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return V26CTA(
      label,
      onPressed: onTap,
      variant: filled ? V26CtaVariant.primary : V26CtaVariant.ghost,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  USER BUBBLE — shown in NavBar when user is logged in
// ══════════════════════════════════════════════════════════════════
class _UserBubble extends StatelessWidget {
  final String? name;
  final String? role;
  final AppLocalizations l10n;
  final VoidCallback onEnterApp;

  const _UserBubble({
    required this.name,
    required this.role,
    required this.l10n,
    required this.onEnterApp,
  });

  String get _initial =>
      (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : '?';

  String _roleLabel(String? r) {
    switch (r) {
      case 'lawyer':
        return l10n.landingRoleLawyer;
      case 'admin':
        return l10n.landingRoleAdmin;
      default:
        return l10n.landingRoleUser;
    }
  }

  Color get _roleColor {
    switch (role) {
      case 'lawyer':
        return V26.gold;
      case 'admin':
        return V26.navy800;
      default:
        return VetoMockup.primaryCta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEnterApp,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_roleColor.withValues(alpha: 0.85), _roleColor],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initial,
                style: const TextStyle(
                  fontFamily: V26.serif,
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name ?? l10n.landingGuestName,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.ink900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _roleLabel(role).toUpperCase(),
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.ink500,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: VetoMockup.primaryCta, size: 12),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  HERO — `2026/landing.html` · eyebrow · split serif title · mini device · proof row
// ══════════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;
  final VoidCallback onTap;
  const _HeroSection(
      {required this.l10n, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = l10n;
    final titleSize = compact ? 34.0 : 64.0;
    final pad = EdgeInsets.fromLTRB(
      compact ? 20 : 56,
      compact ? 24 : 64,
      compact ? 20 : 56,
      compact ? 28 : 44,
    );

    final caption = Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: V26.sans,
          fontSize: 11,
          color: V26.ink500,
          letterSpacing: 0.5,
        ),
        children: [
          TextSpan(text: l.miniStatBefore),
          TextSpan(
            text: l.miniStatEm,
            style: const TextStyle(
              color: V26.ink900,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!compact) TextSpan(text: ' · ${l.miniStatSuffix}'),
        ],
      ),
      textAlign: TextAlign.center,
    );

    final textBlock = _HeroCopyColumn(
      l10n: l,
      compact: compact,
      titleSize: titleSize,
      onTap: onTap,
    );

    final mini = V26LandingMiniDevice(caption: caption);

    return VetoLineArtBackground(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topEnd,
            end: AlignmentDirectional.bottomStart,
            colors: [
              Color(0x1A2E69E7),
              Colors.transparent,
            ],
            stops: [0, 0.65],
          ),
        ),
        child: Padding(
          padding: pad,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        textBlock,
                        const SizedBox(height: 28),
                        mini,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 105, child: textBlock),
                        const SizedBox(width: 48),
                        Expanded(flex: 95, child: mini),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCopyColumn extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;
  final double titleSize;
  final VoidCallback onTap;
  const _HeroCopyColumn({
    required this.l10n,
    required this.compact,
    required this.titleSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = l10n;
    final align =
        compact ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = compact ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
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
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: V26.ok,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: V26.ok.withValues(alpha: 0.18),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.heroEyebrow,
                style: const TextStyle(
                  fontFamily: V26.sans,
                  color: VetoMockup.primaryCta,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.98,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          t.heroTitleL1,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: V26.serif,
            color: V26.ink900,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -0.02 * titleSize,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 0,
          runSpacing: 4,
          children: [
            Text(
              t.heroTitleL2,
              style: TextStyle(
                fontFamily: V26.serif,
                color: V26.ink900,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.02 * titleSize,
              ),
            ),
            _HeroEmphasis(text: t.heroTitleEm, size: titleSize),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          t.heroBody,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: V26.sans,
            color: V26.ink500,
            fontSize: compact ? 14 : 17,
            height: 1.65,
          ),
        ),
        SizedBox(height: compact ? 24 : 28),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            V26CTA(
              t.heroCta,
              onPressed: onTap,
              variant: V26CtaVariant.danger,
              large: true,
              icon: Icons.warning_amber_rounded,
            ),
            V26CTA(
              t.heroSecondary,
              onPressed: onTap,
              variant: V26CtaVariant.ghost,
              large: true,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.only(top: 18),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: V26.hairline)),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: compact ? WrapAlignment.center : WrapAlignment.start,
            children: [
              _LandingProofPair(
                numeral: t.proof1Num,
                label: t.proof1Lbl,
              ),
              _LandingProofPair(
                numeral: t.proof2Num,
                label: t.proof2Lbl,
              ),
              if (!compact)
                _LandingProofPair(
                  numeral: t.proof3Num,
                  label: t.proof3Lbl,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroEmphasis extends StatelessWidget {
  final String text;
  final double size;
  const _HeroEmphasis({required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: V26.serif,
            fontSize: size,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -0.02 * size,
            color: VetoMockup.primaryCta,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -10,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: V26.goldSoft.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class _LandingProofPair extends StatelessWidget {
  final String numeral;
  final String label;
  const _LandingProofPair({required this.numeral, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numeral,
          style: const TextStyle(
            fontFamily: V26.serif,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: V26.ink900,
            height: 1,
          ),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 112),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 11,
              color: V26.ink500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  STATS BAR
// ══════════════════════════════════════════════════════════════════
class _StatsBar extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;
  const _StatsBar({required this.l10n, required this.compact});

  @override
  Widget build(BuildContext context) {
    final l = l10n;
    final stats = [
      (l.stat1num, l.stat1lbl),
      (l.stat2num, l.stat2lbl),
      (l.stat3num, l.stat3lbl),
      (l.stat4num, l.stat4lbl),
    ];
    final hPad = compact ? 20.0 : 56.0;

    Widget cell((String, String) s) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Column(
          children: [
            Text(
              s.$1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: V26.serif,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: V26.ink900,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 11,
                color: V26.ink500,
                height: 1.3,
                letterSpacing: 0.66,
              ),
            ),
          ],
        ),
      );
    }

    final inner = compact
        ? Table(
            border: TableBorder.all(color: V26.hairline),
            children: [
              TableRow(children: [cell(stats[0]), cell(stats[1])]),
              TableRow(children: [cell(stats[2]), cell(stats[3])]),
            ],
          )
        : Table(
            border: TableBorder.all(color: V26.hairline),
            children: [
              TableRow(children: stats.map(cell).toList()),
            ],
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(V26.rLg),
            child: inner,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  STACK SECTION — the 3-step "רצף תגובה" panel (matches mockup card)
// ══════════════════════════════════════════════════════════════════
class _StackSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;
  const _StackSection({required this.l10n, required this.compact});

  @override
  Widget build(BuildContext context) {
    final t = l10n;
    final steps = [
      ('01', t.stack1Title, t.stack1Body),
      ('02', t.stack2Title, t.stack2Body),
      ('03', t.stack3Title, t.stack3Body),
    ];
    final hPad = compact ? 20.0 : 56.0;
    final vPad = compact ? 24.0 : 48.0;

    final cols = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(height: 18),
                _StackStepBlock(
                  numeral: steps[i].$1,
                  title: steps[i].$2,
                  body: steps[i].$3,
                ),
              ],
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: _StackStepBlock(
                    numeral: steps[i].$1,
                    title: steps[i].$2,
                    body: steps[i].$3,
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 24),
              ],
            ],
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: V26Card(
            lift: true,
            radius: V26.r2xl,
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 56, vertical: vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: V26Kicker(t.stackKicker)),
                const SizedBox(height: 8),
                Text(
                  t.stackTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: V26.serif,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: V26.ink900,
                  ),
                ),
                const SizedBox(height: 20),
                cols,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StackStepBlock extends StatelessWidget {
  final String numeral;
  final String title;
  final String body;
  const _StackStepBlock({
    required this.numeral,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numeral,
          style: TextStyle(
            fontFamily: V26.serif,
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: VetoMockup.primaryCta.withValues(alpha: 0.16),
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: V26.serif,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: V26.ink900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            fontFamily: V26.sans,
            fontSize: 13.5,
            height: 1.6,
            color: V26.ink500,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  FEATURES — white `.feature` cards (`2026/landing.html`)
// ══════════════════════════════════════════════════════════════════
class _FeaturesSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;
  const _FeaturesSection({required this.l10n, required this.compact});

  @override
  Widget build(BuildContext context) {
    final t = l10n;
    final features = [
      (
        Icons.bolt_rounded,
        VetoMockup.primaryCtaDeep,
        t.feat1Title,
        t.feat1Body
      ),
      (
        Icons.chat_bubble_rounded,
        VetoMockup.primaryCta,
        t.feat2Title,
        t.feat2Body
      ),
      (Icons.lock_rounded, V26.ok, t.feat3Title, t.feat3Body),
    ];
    final hPad = compact ? 20.0 : 56.0;
    final gap = compact ? 12.0 : 18.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < features.length; i++) ...[
                      if (i > 0) SizedBox(height: gap),
                      _FeatureCard(
                        icon: features[i].$1,
                        iconColor: features[i].$2,
                        title: features[i].$3,
                        body: features[i].$4,
                      ),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < features.length; i++) ...[
                      Expanded(
                        child: _FeatureCard(
                          icon: features[i].$1,
                          iconColor: features[i].$2,
                          title: features[i].$3,
                          body: features[i].$4,
                        ),
                      ),
                      if (i < features.length - 1) SizedBox(width: gap),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, body;
  const _FeatureCard(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.body});

  @override
  Widget build(BuildContext context) {
    return V26Card(
      radius: V26.rLg,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [V26.surface, V26.navy100],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: V26.hairline),
              boxShadow: V26.shadow1,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontFamily: V26.serif,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: V26.ink900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontFamily: V26.sans,
              fontSize: 13.5,
              height: 1.55,
              color: V26.ink500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  PRICING
// ══════════════════════════════════════════════════════════════════
class _PricingSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;
  final VoidCallback onTap;
  const _PricingSection(
      {required this.l10n, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = l10n;
    final lines = <String>[
      t.pricingLine1,
      t.pricingLine2,
      t.pricingLine3,
      t.pricingLine4,
      t.pricingLine5,
    ];
    final hPad = compact ? 24.0 : 56.0;

    final checklist = Column(
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: V26.okSoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF16664B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontFamily: V26.sans,
                      fontSize: 14,
                      height: 1.5,
                      color: V26.ink700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final header = Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        V26Badge(t.pricingTitle, tone: V26BadgeTone.brand),
        const SizedBox(height: 12),
        Text(
          t.pricingHeroTitle,
          style: TextStyle(
            fontFamily: V26.serif,
            fontSize: compact ? 32 : 38,
            fontWeight: FontWeight.w700,
            color: V26.ink900,
          ),
          textAlign: compact ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment:
              compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Text(
              t.pricingPrice,
              style: const TextStyle(
                fontFamily: V26.serif,
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: VetoMockup.primaryCta,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              t.pricingPeriod,
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: V26.ink500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          t.pricingIntro,
          style: const TextStyle(
            fontFamily: V26.sans,
            fontSize: 14,
            height: 1.5,
            color: V26.ink500,
          ),
          textAlign: compact ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),
        V26CTA(
          t.pricingGetStarted,
          onPressed: onTap,
          variant: V26CtaVariant.primary,
          large: true,
          expanded: compact,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [V26.surface, V26.surface2],
              ),
              borderRadius: BorderRadius.circular(V26.r2xl),
              border: Border.all(color: V26.hairline),
              boxShadow: V26.shadow2,
            ),
            padding: EdgeInsets.all(compact ? 24 : 48),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: 28),
                      checklist,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: header),
                      const SizedBox(width: 24),
                      Expanded(child: checklist),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TESTIMONIALS
// ══════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════
//  CTA SECTION
// ══════════════════════════════════════════════════════════════════
class _CtaSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;
  final VoidCallback onTap;
  const _CtaSection(
      {required this.l10n, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = l10n;
    final hPad = compact ? 24.0 : 56.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, compact ? 48 : 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(V26.r2xl),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [VetoMockup.primaryCtaDeep, VetoMockup.primaryCta],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -80,
                    right: -60,
                    child: IgnorePointer(
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              V26.gold.withValues(alpha: 0.20),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 24 : 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.ctaTitle,
                          style: TextStyle(
                            fontFamily: V26.serif,
                            color: Colors.white,
                            fontSize: compact ? 30 : 36,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.ctaBody,
                          style: const TextStyle(
                            fontFamily: V26.sans,
                            color: Color(0xFFC7D5EE),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            V26CTA(
                              t.ctaBtn,
                              onPressed: onTap,
                              variant: V26CtaVariant.gold,
                              large: true,
                            ),
                            V26CTA(
                              t.ctaSecondary,
                              onPressed: onTap,
                              variant: V26CtaVariant.ghostLight,
                              large: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  FOOTER
// ══════════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final AppLocalizations l10n;
  const _Footer({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final l = l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: V26.hairline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.footer,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: _C.inkLight, fontSize: 12, height: 1.8),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              _FooterLink(
                label: l.linkPrivacy,
                onTap: () => Navigator.pushNamed(context, '/privacy'),
              ),
              _footerDot(),
              _FooterLink(
                label: l.linkTerms,
                onTap: () => Navigator.pushNamed(context, '/terms'),
              ),
              _footerDot(),
              _FooterLink(
                label: l.linkContact,
                onTap: () {},
              ),
              _footerDot(),
              _FooterLink(
                label: l.linkCareers,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerDot() => Text(
        ' · ',
        style: TextStyle(color: _C.inkLight.withValues(alpha: 0.5)),
      );
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: _C.accent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: _C.accent,
        ),
      ),
    );
  }
}

