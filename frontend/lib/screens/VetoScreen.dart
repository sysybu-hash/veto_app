// ============================================================
//  VetoScreen.dart — VETO Legal Emergency App
//  Main Screen: The VETO Button Experience
//  Tech: Flutter | Design: Luxury Minimalist – Deep Navy & Silver
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand Colors ───────────────────────────────────────────
class VetoColors {
  static const Color background = Color(0xFF001F3F);   // Deep Navy
  static const Color silver     = Color(0xFFC0C2C9);   // Silver / Chrome
  static const Color silverDim  = Color(0xFF8A8C93);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color safe       = Color(0xFF2ECC71);   // Status: Secure
  static const Color searchPulse= Color(0xFFC0C2C9);   // Status: Searching
  static const Color overlay    = Color(0x22C0C2C9);   // Ring overlay
}

// ── Supported Languages ────────────────────────────────────
enum VetoLanguage { en, he, ar }

class VetoL10n {
  static const Map<VetoLanguage, Map<String, String>> _data = {
    VetoLanguage.en: {
      'label':      'EN',
      'statusSafe': 'Status: Secure',
      'statusSearch':'Status: Searching for Lawyer...',
      'veto':       'VETO',
      'hint':       'Press & Hold to Activate',
      'camera':     'Evidence',
      'mic':        'Record',
      'tagline':    'Your Legal Emergency Shield',
    },
    VetoLanguage.he: {
      'label':      'עב',
      'statusSafe': 'סטטוס: מוגן',
      'statusSearch':'סטטוס: מחפש עורך דין...',
      'veto':       'VETO',
      'hint':       'לחץ והחזק להפעלה',
      'camera':     'ראיות',
      'mic':        'הקלטה',
      'tagline':    'מגן החירום המשפטי שלך',
    },
    VetoLanguage.ar: {
      'label':      'ع',
      'statusSafe': 'الحالة: آمن',
      'statusSearch':'الحالة: جارٍ البحث عن محامٍ...',
      'veto':       'VETO',
      'hint':       'اضغط مع الاستمرار للتفعيل',
      'camera':     'أدلة',
      'mic':        'تسجيل',
      'tagline':    'درعك القانوني في الطوارئ',
    },
  };

  static String get(VetoLanguage lang, String key) =>
      _data[lang]?[key] ?? '';

  static TextDirection directionOf(VetoLanguage lang) =>
      (lang == VetoLanguage.en) ? TextDirection.ltr : TextDirection.rtl;
}

// ══════════════════════════════════════════════════════════════
//  VetoScreen — Main Widget
// ══════════════════════════════════════════════════════════════
class VetoScreen extends StatefulWidget {
  const VetoScreen({super.key});

  @override
  State<VetoScreen> createState() => _VetoScreenState();
}

class _VetoScreenState extends State<VetoScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────
  VetoLanguage _lang   = VetoLanguage.en;
  bool _isSearching    = false;

  // ── Animation Controllers ──────────────────────────────────
  late final AnimationController _pulseCtrl;   // outer ring pulse
  late final AnimationController _glowCtrl;    // button inner glow
  late final AnimationController _statusCtrl;  // status text fade
  late final AnimationController _ringCtrl;    // secondary ring
  late final AnimationController _idleCtrl;    // idle breathing

  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _glowRadius;
  late Animation<double> _idleScale;
  late Animation<double> _statusOpacity;

  // ── Timer (auto-stop demo) ─────────────────────────────────
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    _idleCtrl.repeat(reverse: true);
  }

  void _buildAnimations() {
    // Idle breathing on the button
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _idleScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut),
    );

    // Primary pulse ring
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.85).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    // Secondary staggered ring
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _ringScale = Tween<double>(begin: 1.0, end: 2.3).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );

    // Button glow radius
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowRadius = Tween<double>(begin: 0, end: 38).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Status text fade
    _statusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _statusOpacity = Tween<double>(begin: 1, end: 0.35).animate(
      CurvedAnimation(parent: _statusCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _statusCtrl.dispose();
    _ringCtrl.dispose();
    _idleCtrl.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  // ── Activate / Deactivate VETO ─────────────────────────────
  void _activateVeto() {
    if (_isSearching) return;
    HapticFeedback.heavyImpact();

    setState(() => _isSearching = true);

    _idleCtrl.stop();
    _pulseCtrl.repeat();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ringCtrl.repeat();
    });
    _glowCtrl.forward();
    _statusCtrl.repeat(reverse: true);

    // Demo: auto-stop after 8s (replace with real dispatch result)
    _searchTimer = Timer(const Duration(seconds: 8), _stopVeto);
  }

  void _stopVeto() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    setState(() => _isSearching = false);

    _pulseCtrl.stop();
    _ringCtrl.stop();
    _glowCtrl.reverse();
    _statusCtrl.stop();
    _statusCtrl.animateTo(1.0);
    _idleCtrl.repeat(reverse: true);
    _searchTimer?.cancel();
  }

  // ── Language Switcher ──────────────────────────────────────
  void _cycleLang() {
    setState(() {
      _lang = VetoLanguage.values[
          (_lang.index + 1) % VetoLanguage.values.length];
    });
  }

  // ── Helpers ────────────────────────────────────────────────
  String _t(String key) => VetoL10n.get(_lang, key);
  TextDirection get _dir => VetoL10n.directionOf(_lang);

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        backgroundColor: VetoColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildStatusBar(),
              const Spacer(flex: 2),
              _buildTagline(),
              const SizedBox(height: 28),
              _buildVetoButton(),
              const SizedBox(height: 16),
              _buildHintText(),
              const Spacer(flex: 3),
              _buildBottomActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Bar (Language Switcher) ────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _LanguageSwitcher(
            currentLang: _lang,
            onTap: _cycleLang,
          ),
        ],
      ),
    );
  }

  // ── Status Bar ─────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: _statusOpacity,
        builder: (_, __) {
          return Opacity(
            opacity: _isSearching ? _statusOpacity.value : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSearching
                        ? VetoColors.searchPulse
                        : VetoColors.safe,
                    boxShadow: [
                      BoxShadow(
                        color: (_isSearching
                                ? VetoColors.searchPulse
                                : VetoColors.safe)
                            .withOpacity(0.7),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isSearching ? _t('statusSearch') : _t('statusSafe'),
                  style: TextStyle(
                    color: _isSearching
                        ? VetoColors.silver
                        : VetoColors.safe,
                    fontSize: 13,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Tagline ────────────────────────────────────────────────
  Widget _buildTagline() {
    return Text(
      _t('tagline'),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: VetoColors.silver.withOpacity(0.45),
        fontSize: 12,
        letterSpacing: 2.0,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  // ── Hint Text ─────────────────────────────────────────────
  Widget _buildHintText() {
    return AnimatedOpacity(
      opacity: _isSearching ? 0.0 : 0.55,
      duration: const Duration(milliseconds: 400),
      child: Text(
        _t('hint'),
        style: const TextStyle(
          color: VetoColors.silver,
          fontSize: 12,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  // ── VETO Button ────────────────────────────────────────────
  Widget _buildVetoButton() {
    const double btnSize = 200.0;

    return GestureDetector(
      onLongPress: _activateVeto,
      onDoubleTap: _activateVeto,
      onTap: _isSearching ? _stopVeto : null,
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_pulseCtrl, _ringCtrl, _glowCtrl, _idleCtrl]),
        builder: (context, child) {
          return SizedBox(
            width: btnSize * 2.5,
            height: btnSize * 2.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer diffuse ring (secondary)
                if (_isSearching)
                  _buildRing(
                    size: btnSize,
                    scale: _ringScale.value,
                    opacity: _ringOpacity.value,
                    color: VetoColors.silver,
                    strokeWidth: 1.0,
                  ),
                // Inner pulse ring (primary)
                if (_isSearching)
                  _buildRing(
                    size: btnSize,
                    scale: _pulseScale.value,
                    opacity: _pulseOpacity.value,
                    color: VetoColors.white,
                    strokeWidth: 1.8,
                  ),
                // Main button
                Transform.scale(
                  scale: _isSearching ? 1.0 : _idleScale.value,
                  child: _VetoButtonCore(
                    size: btnSize,
                    glowRadius: _glowRadius.value,
                    isActive: _isSearching,
                    label: _t('veto'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRing({
    required double size,
    required double scale,
    required double opacity,
    required Color color,
    required double strokeWidth,
  }) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: strokeWidth),
          ),
        ),
      ),
    );
  }

  // ── Bottom Action Icons ────────────────────────────────────
  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionIcon(
          icon: Icons.camera_alt_outlined,
          label: _t('camera'),
          onTap: () => _handleAction('camera'),
        ),
        const SizedBox(width: 64),
        _ActionIcon(
          icon: Icons.mic_none_rounded,
          label: _t('mic'),
          onTap: () => _handleAction('mic'),
        ),
      ],
    );
  }

  void _handleAction(String action) {
    HapticFeedback.selectionClick();
    // TODO: wire to cloud upload service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: VetoColors.silver.withOpacity(0.15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          action == 'camera' ? '📷 Evidence captured' : '🎙 Recording started',
          style: const TextStyle(color: VetoColors.white, fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _VetoButtonCore — The Button Itself
// ══════════════════════════════════════════════════════════════
class _VetoButtonCore extends StatelessWidget {
  final double size;
  final double glowRadius;
  final bool isActive;
  final String label;

  const _VetoButtonCore({
    required this.size,
    required this.glowRadius,
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VetoColors.background,
        border: Border.all(
          color: isActive ? VetoColors.white : VetoColors.silver,
          width: isActive ? 2.5 : 1.8,
        ),
        boxShadow: [
          // Outer silver rim glow
          BoxShadow(
            color: VetoColors.silver.withOpacity(isActive ? 0.55 : 0.18),
            blurRadius: isActive ? glowRadius + 12 : 16,
            spreadRadius: isActive ? 4 : 0,
          ),
          // Inner depth shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
          // Inner highlight
          BoxShadow(
            color: VetoColors.silver.withOpacity(isActive ? 0.22 : 0.07),
            blurRadius: glowRadius,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // VETO Text
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isActive
                    ? [VetoColors.white, VetoColors.silver]
                    : [VetoColors.silver, VetoColors.silverDim],
              ).createShader(bounds),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 10,
                  color: Colors.white, // masked by ShaderMask
                  shadows: isActive
                      ? [
                          Shadow(
                            color: VetoColors.white.withOpacity(0.6),
                            blurRadius: 18,
                          )
                        ]
                      : null,
                ),
              ),
            ),
            // Active indicator dots
            AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _SearchingDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _SearchingDots — Animated ellipsis while dispatching
// ══════════════════════════════════════════════════════════════
class _SearchingDots extends StatefulWidget {
  @override
  State<_SearchingDots> createState() => _SearchingDotsState();
}

class _SearchingDotsState extends State<_SearchingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _dot = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dot = (_dot + 1) % 3);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final bool lit = i <= _dot;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit
                ? VetoColors.silver
                : VetoColors.silver.withOpacity(0.2),
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _LanguageSwitcher
// ══════════════════════════════════════════════════════════════
class _LanguageSwitcher extends StatelessWidget {
  final VetoLanguage currentLang;
  final VoidCallback onTap;

  const _LanguageSwitcher(
      {required this.currentLang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VetoColors.silver.withOpacity(0.35)),
          color: VetoColors.silver.withOpacity(0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              VetoL10n.get(currentLang, 'label'),
              style: const TextStyle(
                color: VetoColors.silver,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.language_rounded,
                color: VetoColors.silverDim, size: 14),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  _ActionIcon — Bottom camera / mic buttons
// ══════════════════════════════════════════════════════════════
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VetoColors.silver.withOpacity(0.07),
              border:
                  Border.all(color: VetoColors.silver.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: VetoColors.silver.withOpacity(0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon,
                color: VetoColors.silver.withOpacity(0.75), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: VetoColors.silver.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
