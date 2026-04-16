// ═══════════════════════════════════════════════════════════════════
//  VETO Landing Page — Pixel-perfect rebuild per approved mockup
//  Light Aurora Glassmorphism: centred hero, red SOS orb, white cards
// ═══════════════════════════════════════════════════════════════════

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';
import '../widgets/accessibility_toolbar.dart';
import '../widgets/ai_chat_dialog.dart';

// ── Palette — dark glassmorphism (fluid aurora + white type) ─────
class _C {
  static const bg         = VetoGlassTokens.bgBase;
  static const white      = Color(0xFFFFFFFF);
  static const navBg      = VetoGlassTokens.glassFill;
  static const inkDark    = VetoGlassTokens.textPrimary;
  static const inkMid     = VetoGlassTokens.textSecondary;
  static const inkLight   = VetoGlassTokens.textMuted;
  static const accent     = VetoGlassTokens.neonCyan;
  static const red        = Color(0xFFFF3B3B);
  static const border     = VetoGlassTokens.glassBorder;
  static const cardBg     = VetoGlassTokens.glassFillStrong;
}

// ── i18n ──────────────────────────────────────────────────────────
class _T {
  static String get(String code, String k) =>
      (_copy[AppLanguage.normalize(code)] ?? _copy['he']!)[k] ?? k;

  static const _copy = <String, Map<String, String>>{
    'he': {
      'navHome':       'בית',
      'navFeatures':   'תכונות',
      'navPricing':    'תמחור',
      'navContact':    'צור קשר',
      'navLogin':      'כניסה',
      'navRegister':   'הרשמה',
      'heroTitle':     'ההגנה המשפטית שלך — תמיד בהישג יד',
      'heroBody':      'VETO מחברת אותך לעורך דין תוך שניות בכל מצב חירום',
      'heroCta':       'לחץ SOS',
      'heroSecondary': 'גלה עוד',
      'proof1':        '4.9/5',
      'proof1sub':     '',
      'proof2':        'תוך שניות',
      'proof3':        'מאובטח',
      'feat1Title':    'הגנה מיידית',
      'feat1Body':     'הגנה משפטית לעורך דין תוך שניות בכל מצב חירום',
      'feat2Title':    'קשר ישיר עם עורך דין',
      'feat2Body':     'קשר ישיר עם עורך דין – שניות בכל חירום',
      'feat3Title':    'פרטיות מלאה',
      'feat3Body':     'פרטיות מלאה לעורך דין, שניות... מצב חירום',
      'statTitle':     'למה VETO?',
      'stat1num':      '24/7',  'stat1lbl': 'Legal Protection',
      'stat2num':      'Real',  'stat2lbl': 'Lawyers',
      'stat3num':      '+3',    'stat3lbl': 'Languages',
      'stat4num':      'Live',  'stat4lbl': 'Dispatch',
      'stackTitle':    'רצף תגובה אחד',
      'stack1Title':   'זיהוי מצב',
      'stack1Body':    'עוצרים, נחקרים, עצורים או מעורבים בתאונה? המערכת מתאימה מענה מיידי לסיטואציה.',
      'stack2Title':   'שיחה עם AI',
      'stack2Body':    'הסוכן מסדר את הידע, מחדד שאלות, ומכוון לצעד המשפטי הבא בשפה שנוחה לך.',
      'stack3Title':   'חיבור אנושי',
      'stack3Body':    'אם אין צורך עורך דין, המשרד מזניק איש מקצוע זמין עם עדיפות לשפה הרלוונטית.',
      'pricingTitle':  'מנוי חודשי',
      'pricingPrice':  '₪19.90',
      'pricingPeriod': 'לחודש',
      'pricingLine1':  'עוזר AI משפטי ללא הגבלה',
      'pricingLine2':  'תרחישים, זכויות ותיעוד ראיות',
      'pricingLine3':  'שיגור עורך דין באירוע חי לפי שימוש',
      'ctaTitle':      'בונים שכבת הגנה לפני שהאירוע מתחיל',
      'ctaBody':       'ההרשמה קצרה. מהרגע שהיא מסתיימת, כל חירום משפטי מקבל מסך ברור ומוכן לפעולה.',
      'ctaBtn':        'לעבור לאשף',
      'footer':        'VETO LEGAL | מערכת תגובה משפטית חכמה, מהירה ורב-לשונית',
    },
    'en': {
      'navHome':       'Home',
      'navFeatures':   'Features',
      'navPricing':    'Pricing',
      'navContact':    'Contact',
      'navLogin':      'Sign in',
      'navRegister':   'Sign up',
      'heroTitle':     'Your Legal Protection — Always Within Reach',
      'heroBody':      'VETO connects you with a lawyer within seconds in any emergency',
      'heroCta':       'SOS',
      'heroSecondary': 'Learn more',
      'proof1':        '4.9/5',
      'proof1sub':     '',
      'proof2':        'Seconds',
      'proof3':        'Secure',
      'feat1Title':    'Immediate Protection',
      'feat1Body':     'Legal protection connecting you with a lawyer in seconds during any emergency.',
      'feat2Title':    'Direct Lawyer Contact',
      'feat2Body':     'Direct connection with a lawyer — seconds away in any emergency.',
      'feat3Title':    'Full Privacy',
      'feat3Body':     'Complete privacy. Your data stays yours, always encrypted.',
      'statTitle':     'Why VETO?',
      'stat1num':      '24/7',  'stat1lbl': 'Legal Protection',
      'stat2num':      'Real',  'stat2lbl': 'Lawyers',
      'stat3num':      '+3',    'stat3lbl': 'Languages',
      'stat4num':      'Live',  'stat4lbl': 'Dispatch',
      'stackTitle':    'One Response Chain',
      'stack1Title':   'Situation Detection',
      'stack1Body':    'Stopped, questioned, detained or in an accident? The system adapts instantly.',
      'stack2Title':   'AI Conversation',
      'stack2Body':    'The assistant structures facts, sharpens questions, and guides your next legal move.',
      'stack3Title':   'Human Connection',
      'stack3Body':    'If a lawyer is needed, the platform dispatches one with language-aware matching.',
      'pricingTitle':  'Monthly Plan',
      'pricingPrice':  '₪19.90',
      'pricingPeriod': 'per month',
      'pricingLine1':  'Unlimited legal AI assistant',
      'pricingLine2':  'Rights scenarios and evidence tools',
      'pricingLine3':  'Live lawyer dispatch billed by event',
      'ctaTitle':      'Build your legal safety layer before the incident begins',
      'ctaBody':       'Registration is short. Once done, every legal emergency starts from one clear interface.',
      'ctaBtn':        'Open the wizard',
      'footer':        'VETO LEGAL | Fast, intelligent, multilingual legal response',
    },
    'ru': {
      'navHome':       'Главная',
      'navFeatures':   'Функции',
      'navPricing':    'Тарифы',
      'navContact':    'Контакты',
      'navLogin':      'Вход',
      'navRegister':   'Регистрация',
      'heroTitle':     'Ваша юридическая защита — всегда рядом',
      'heroBody':      'VETO соединяет вас с адвокатом за секунды в любой экстренной ситуации',
      'heroCta':       'SOS',
      'heroSecondary': 'Узнать больше',
      'proof1':        '4.9/5',
      'proof1sub':     '',
      'proof2':        'За секунды',
      'proof3':        'Защищено',
      'feat1Title':    'Мгновенная защита',
      'feat1Body':     'Юридическая защита — адвокат за секунды в любой чрезвычайной ситуации.',
      'feat2Title':    'Прямой контакт с адвокатом',
      'feat2Body':     'Прямое соединение с адвокатом — секунды при любой экстренной ситуации.',
      'feat3Title':    'Полная конфиденциальность',
      'feat3Body':     'Полная приватность. Ваши данные всегда зашифрованы.',
      'statTitle':     'Почему VETO?',
      'stat1num':      '24/7',  'stat1lbl': 'Защита',
      'stat2num':      'Живые', 'stat2lbl': 'Адвокаты',
      'stat3num':      '+3',    'stat3lbl': 'Языка',
      'stat4num':      'Живой', 'stat4lbl': 'Вызов',
      'stackTitle':    'Одна цепочка реакции',
      'stack1Title':   'Определение ситуации',
      'stack1Body':    'Остановка, допрос, задержание или ДТП? Система сразу адаптирует ответ.',
      'stack2Title':   'Диалог с AI',
      'stack2Body':    'Помощник структурирует факты и ведёт к следующему юридическому шагу.',
      'stack3Title':   'Связь с человеком',
      'stack3Body':    'Если нужен адвокат, платформа вызывает специалиста с учётом языка.',
      'pricingTitle':  'Ежемесячный план',
      'pricingPrice':  '₪19.90',
      'pricingPeriod': 'в месяц',
      'pricingLine1':  'Безлимитный юридический AI',
      'pricingLine2':  'Сценарии прав и сбор доказательств',
      'pricingLine3':  'Вызов адвоката по событию',
      'ctaTitle':      'Создайте защитный слой до начала инцидента',
      'ctaBody':       'Регистрация занимает минуту. После этого любая экстренная ситуация начинается с одного экрана.',
      'ctaBtn':        'Перейти к мастеру',
      'footer':        'VETO LEGAL | Быстрая, умная и мультиязычная юридическая реакция',
    },
  };
}

// ══════════════════════════════════════════════════════════════════
//  ROOT WIDGET
// ══════════════════════════════════════════════════════════════════
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _goNext(BuildContext context) async {
    final token = await AuthService().getToken();
    if (!context.mounted) return;
    if (token != null && token.isNotEmpty) {
      final role = await AuthService().getStoredRole() ?? 'user';
      if (!context.mounted) return;
      if (role == 'lawyer') {
        Navigator.pushNamed(context, '/lawyer_dashboard');
      } else if (role == 'admin') {
        Navigator.pushNamed(context, '/admin_settings');
      } else {
        Navigator.pushNamed(context, '/veto_screen');
      }
      return;
    }
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final code    = context.watch<AppLanguageController>().code;
    final dir     = AppLanguage.directionOf(code);
    final w       = MediaQuery.of(context).size.width;
    final compact = w < 860;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: _C.bg,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AiChatDialog(code: code),
          ),
          backgroundColor: const Color(0xFF00B4D4),
          foregroundColor: const Color(0xFF06101C),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(
            code == 'he' ? 'שאל את VETO AI'
                : code == 'ru' ? 'Спросить VETO AI'
                : 'Ask VETO AI',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Stack(
          children: [
            // ── Aurora background ────────────────────────────
            Positioned.fill(child: CustomPaint(painter: VetoFluidBackgroundPainter())),
            // ── Scrollable content ───────────────────────────
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NavBar(code: code, compact: compact, onTap: () => _goNext(context)),
                  _HeroSection(code: code, compact: compact, onTap: () => _goNext(context)),
                  _StatsBar(code: code),
                  _StackSection(code: code, compact: compact),
                  _FeaturesSection(code: code, compact: compact),
                  _PricingSection(code: code, compact: compact, onTap: () => _goNext(context)),
                  _TestimonialsSection(code: code, compact: compact),
                  _CtaSection(code: code, compact: compact, onTap: () => _goNext(context)),
                  _Footer(code: code),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  NAV BAR — white frosted, logo right, links + buttons left
// ══════════════════════════════════════════════════════════════════
class _NavBar extends StatefulWidget {
  final String code;
  final bool compact;
  final VoidCallback onTap;
  const _NavBar({required this.code, required this.compact, required this.onTap});

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
      if (mounted) setState(() { _loggedIn = true; _role = r; _name = n; });
    }
  }

  void _enterApp(BuildContext ctx) {
    if (_role == 'lawyer')     Navigator.pushNamed(ctx, '/lawyer_dashboard');
    else if (_role == 'admin') Navigator.pushNamed(ctx, '/admin_settings');
    else                       Navigator.pushNamed(ctx, '/veto_screen');
  }

  @override
  Widget build(BuildContext context) {
    final t = _T.get;
    final c = widget.code;
    final navItems = [t(c,'navHome'), t(c,'navFeatures'), t(c,'navPricing'), t(c,'navContact')];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: VetoGlassTokens.blurSigma, sigmaY: VetoGlassTokens.blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: _C.navBg,
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            boxShadow: [
              BoxShadow(color: VetoGlassTokens.neonBlue.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(
                children: [
              // ── Logo ──
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: VetoGlassTokens.neonButton,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.35), blurRadius: 12),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF06101C), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('VETO', style: TextStyle(
                  color: _C.inkDark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3,
                )),
              ]),

              // ── Nav links (desktop) ──
              if (!widget.compact) ...[
                const SizedBox(width: 32),
                ...navItems.map((item) => TextButton(
                  onPressed: widget.onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: _C.inkMid,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  child: Text(item),
                )),
              ],

              const Spacer(),

              // ── Accessibility + Language ──
              IconButton(
                icon: const Icon(Icons.accessibility_new_rounded, color: _C.inkMid, size: 20),
                onPressed: () => showAccessibilitySheet(context),
                tooltip: c == 'he' ? 'נגישות' : c == 'ru' ? 'Доступность' : 'Accessibility',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const AppLanguageMenu(compact: true),
              const SizedBox(width: 8),

              // ── Auth: user bubble or login buttons ──
              if (_loggedIn)
                _UserBubble(
                  name: _name,
                  role: _role,
                  code: c,
                  onEnterApp: () => _enterApp(context),
                )
              else ...[
                _NavBtn(label: t(c, 'navLogin'), filled: false, onTap: widget.onTap),
                const SizedBox(width: 8),
                _NavBtn(label: t(c, 'navRegister'), filled: true, onTap: widget.onTap),
              ],
                ],
              ),
            ),
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
  const _NavBtn({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: VetoGlassTokens.neonButton,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.4), blurRadius: 14, spreadRadius: 0),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF06101C),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _C.inkDark,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(48, 40),
      ),
      child: Text(label),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  USER BUBBLE — shown in NavBar when user is logged in
// ══════════════════════════════════════════════════════════════════
class _UserBubble extends StatelessWidget {
  final String? name;
  final String? role;
  final String code;
  final VoidCallback onEnterApp;

  const _UserBubble({
    required this.name,
    required this.role,
    required this.code,
    required this.onEnterApp,
  });

  String get _initial => (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : '?';

  String _roleLabel(String? r) {
    switch (r) {
      case 'lawyer': return code == 'he' ? 'עו"ד' : code == 'ru' ? 'Адвокат' : 'Lawyer';
      case 'admin':  return code == 'he' ? 'מנהל' : code == 'ru' ? 'Админ'  : 'Admin';
      default:       return code == 'he' ? 'משתמש' : code == 'ru' ? 'Польз.' : 'User';
    }
  }

  Color get _roleColor {
    switch (role) {
      case 'lawyer': return const Color(0xFF00C9B1);
      case 'admin':  return const Color(0xFFFF8A00);
      default:       return const Color(0xFF5B8FFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEnterApp,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: VetoGlassTokens.glassFillStrong,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VetoGlassTokens.glassBorderBright, width: 1),
          boxShadow: [
            BoxShadow(color: VetoGlassTokens.neonBlue.withValues(alpha: 0.15), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circle
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.15),
                border: Border.all(color: _roleColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Center(
                child: Text(
                  _initial,
                  style: TextStyle(color: _roleColor, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Name + role
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name ?? (code == 'he' ? 'משתמש' : 'User'),
                  style: const TextStyle(
                    color: VetoGlassTokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _roleLabel(role),
                    style: TextStyle(color: _roleColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Enter arrow
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                gradient: VetoGlassTokens.neonButton,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  code == 'he' ? 'כניסה' : code == 'ru' ? 'Войти' : 'Enter',
                  style: const TextStyle(color: Color(0xFF06101C), fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  HERO — centred, big title, SOS red button, proof chips
// ══════════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final String code;
  final bool compact;
  final VoidCallback onTap;
  const _HeroSection({required this.code, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = _T.get;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, compact ? 64 : 96, 24, compact ? 64 : 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Title ──
              Text(
                t(code, 'heroTitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _C.inkDark,
                  fontSize: compact ? 32 : 48,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // ── Body ──
              Text(
                t(code, 'heroBody'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.inkLight, fontSize: 17, height: 1.65),
              ),
              const SizedBox(height: 40),

              // ── CTA Buttons ──
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  // SOS red button
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                      decoration: BoxDecoration(
                        color: _C.red,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(color: _C.red.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 6)),
                          BoxShadow(color: _C.red.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 8),
                        ],
                      ),
                      child: Text(
                        t(code, 'heroCta'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Secondary outline button
                  OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.inkDark,
                      side: const BorderSide(color: _C.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      backgroundColor: _C.white,
                    ),
                    child: Text(t(code, 'heroSecondary')),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── Proof chips row ──
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 8,
                children: [
                  _ProofChip(icon: Icons.star_rounded, iconColor: const Color(0xFFF59E0B), label: t(code, 'proof1'), sublabel: code == 'he' ? 'דירוג' : 'Rating'),
                  _ProofChip(icon: Icons.bolt_rounded, iconColor: _C.accent, label: t(code, 'proof2'), sublabel: code == 'he' ? 'תגובה' : code == 'ru' ? 'Ответ' : 'Response'),
                  _ProofChip(icon: Icons.lock_rounded, iconColor: const Color(0xFF22C55E), label: t(code, 'proof3'), sublabel: code == 'he' ? 'מאובטח' : code == 'ru' ? 'Безопасно' : 'Secure'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  const _ProofChip({required this.icon, required this.iconColor, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: _C.inkDark, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(sublabel, style: const TextStyle(color: _C.inkLight, fontSize: 13)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  STATS BAR
// ══════════════════════════════════════════════════════════════════
class _StatsBar extends StatelessWidget {
  final String code;
  const _StatsBar({required this.code});

  @override
  Widget build(BuildContext context) {
    final t = _T.get;
    final stats = [
      (t(code,'stat1num'), t(code,'stat1lbl')),
      (t(code,'stat2num'), t(code,'stat2lbl')),
      (t(code,'stat3num'), t(code,'stat3lbl')),
      (t(code,'stat4num'), t(code,'stat4lbl')),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        border: const Border.symmetric(horizontal: BorderSide(color: _C.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final s in stats)
                Column(children: [
                  Text(s.$1, style: const TextStyle(
                    color: _C.accent, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1,
                  )),
                  const SizedBox(height: 4),
                  Text(s.$2, style: const TextStyle(color: _C.inkLight, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
            ],
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
  final String code;
  final bool compact;
  const _StackSection({required this.code, required this.compact});

  @override
  Widget build(BuildContext context) {
    final t = _T.get;
    final steps = [
      (Icons.explore_outlined, t(code,'stack1Title'), t(code,'stack1Body')),
      (Icons.auto_awesome_outlined, t(code,'stack2Title'), t(code,'stack2Body')),
      (Icons.notifications_active_outlined, t(code,'stack3Title'), t(code,'stack3Body')),
    ];
    return _Section(
      eyebrow: code == 'he' ? 'איך זה עובד' : code == 'ru' ? 'Как это работает' : 'How it works',
      title: t(code, 'stackTitle'),
      child: Container(
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: _C.border),
              _StackRow(icon: steps[i].$1, title: steps[i].$2, body: steps[i].$3, step: '0${i+1}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _StackRow extends StatelessWidget {
  final IconData icon;
  final String title, body, step;
  const _StackRow({required this.icon, required this.title, required this.body, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _C.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.accent.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: _C.accent, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: _C.inkDark, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: _C.inkLight, fontSize: 13, height: 1.6)),
        ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  FEATURES — 3 white cards (matches mockup exactly)
// ══════════════════════════════════════════════════════════════════
class _FeaturesSection extends StatelessWidget {
  final String code;
  final bool compact;
  const _FeaturesSection({required this.code, required this.compact});

  @override
  Widget build(BuildContext context) {
    final t = _T.get;
    final features = [
      (Icons.shield_rounded,       _C.accent,                    t(code,'feat3Title'), t(code,'feat3Body')),
      (Icons.phone_in_talk_rounded, const Color(0xFF5B8FFF),     t(code,'feat2Title'), t(code,'feat2Body')),
      (Icons.lock_rounded,          const Color(0xFF22C55E),     t(code,'feat1Title'), t(code,'feat1Body')),
    ];
    return _Section(
      eyebrow: code == 'he' ? 'למה VETO' : code == 'ru' ? 'Почему VETO' : 'Why VETO',
      title: code == 'he' ? 'כל מה שאתה צריך ברגע קריטי'
           : code == 'ru' ? 'Всё необходимое в критический момент'
           : 'Everything you need at a critical moment',
      child: compact
          ? Column(children: [
              for (var i = 0; i < features.length; i++) ...[
                _FeatureCard(icon: features[i].$1, iconColor: features[i].$2, title: features[i].$3, body: features[i].$4),
                if (i < features.length - 1) const SizedBox(height: 12),
              ],
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < features.length; i++) ...[
                Expanded(child: _FeatureCard(icon: features[i].$1, iconColor: features[i].$2, title: features[i].$3, body: features[i].$4)),
                if (i < features.length - 1) const SizedBox(width: 16),
              ],
            ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, body;
  const _FeatureCard({required this.icon, required this.iconColor, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withValues(alpha: 0.20)),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(color: _C.inkDark, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: _C.inkLight, fontSize: 14, height: 1.65)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  PRICING
// ══════════════════════════════════════════════════════════════════
class _PricingSection extends StatelessWidget {
  final String code;
  final bool compact;
  final VoidCallback onTap;
  const _PricingSection({required this.code, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = _T.get;
    final lines = [t(code,'pricingLine1'), t(code,'pricingLine2'), t(code,'pricingLine3')];
    final lineColors = [_C.accent, const Color(0xFF22C55E), const Color(0xFFF59E0B)];
    return _Section(
      eyebrow: code == 'he' ? 'תמחור' : code == 'ru' ? 'Тарифы' : 'Pricing',
      title: code == 'he' ? 'מנוי פשוט. ברור. משתלם.'
           : code == 'ru' ? 'Простой. Прозрачный. Выгодный.'
           : 'Simple. Clear. Affordable.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.accent.withValues(alpha: 0.30), width: 1.5),
              boxShadow: [
                BoxShadow(color: _C.accent.withValues(alpha: 0.08), blurRadius: 24),
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t(code,'pricingTitle').toUpperCase(), style: const TextStyle(color: _C.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(t(code,'pricingPrice'), style: const TextStyle(color: _C.inkDark, fontSize: 52, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(t(code,'pricingPeriod'), style: const TextStyle(color: _C.inkLight, fontSize: 15)),
                ),
              ]),
              const SizedBox(height: 8),
              Container(height: 2, width: 44, decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.accent, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              )),
              const SizedBox(height: 24),
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded, color: lineColors[i], size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(lines[i], style: const TextStyle(color: _C.inkMid, fontSize: 14))),
                  ]),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(code == 'he' ? 'התחל עכשיו' : code == 'ru' ? 'Начать' : 'Get started'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TESTIMONIALS
// ══════════════════════════════════════════════════════════════════
class _TestimonialsSection extends StatelessWidget {
  final String code;
  final bool compact;
  const _TestimonialsSection({required this.code, required this.compact});

  static const _reviews = [
    (name: 'David B.',   date: '04/2025', text: 'Having an attorney with me in real time when I needed one was an absolute game changer. The confidence I felt was enough to keep the situation in check.', rating: 5),
    (name: 'Adam H.',    date: '07/2025', text: 'I used this app at a traffic stop. It works great! The licensed attorney was on the phone within seconds. Amazing!', rating: 5),
    (name: 'Mike K.',    date: '09/2025', text: 'The attorney provided excellent support when I was questioned by police while parked. Highly recommend.', rating: 5),
  ];

  @override
  Widget build(BuildContext context) {
    final eyebrow = code == 'he' ? 'מה אומרים המשתמשים' : code == 'ru' ? 'Отзывы' : 'Testimonials';
    final title = code == 'he' ? 'אנשים שהשתמשו ב-VETO ברגע שחשב'
                : code == 'ru' ? 'Люди, которые использовали VETO в важный момент'
                : 'People who used VETO when it mattered';
    return _Section(
      eyebrow: eyebrow,
      title: title,
      child: compact
          ? Column(children: [
              for (var i = 0; i < _reviews.length; i++) ...[
                _ReviewCard(r: _reviews[i]),
                if (i < _reviews.length - 1) const SizedBox(height: 12),
              ],
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < _reviews.length; i++) ...[
                Expanded(child: _ReviewCard(r: _reviews[i])),
                if (i < _reviews.length - 1) const SizedBox(width: 16),
              ],
            ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ({String name, String date, String text, int rating}) r;
  const _ReviewCard({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (int i = 0; i < r.rating; i++)
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
          const Spacer(),
          Text(r.date, style: const TextStyle(color: _C.inkLight, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Text('"${r.text}"', style: const TextStyle(color: _C.inkMid, fontSize: 13, height: 1.65, fontStyle: FontStyle.italic)),
        const SizedBox(height: 14),
        Text(r.name, style: const TextStyle(color: _C.inkDark, fontSize: 13, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  CTA SECTION
// ══════════════════════════════════════════════════════════════════
class _CtaSection extends StatelessWidget {
  final String code;
  final bool compact;
  final VoidCallback onTap;
  const _CtaSection({required this.code, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = _T.get;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 0),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 60 : 80),
      decoration: BoxDecoration(
        color: _C.white,
        border: const Border(top: BorderSide(color: _C.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _C.accent.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _C.accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                code == 'he' ? 'מוכן לצאת לדרך?' : code == 'ru' ? 'Готовы начать?' : 'Ready to get started?',
                style: const TextStyle(color: _C.accent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t(code, 'ctaTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.inkDark, fontSize: compact ? 26 : 36, fontWeight: FontWeight.w900, height: 1.15),
            ),
            const SizedBox(height: 14),
            Text(
              t(code, 'ctaBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.inkLight, fontSize: 15, height: 1.7),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(t(code, 'ctaBtn')),
              style: FilledButton.styleFrom(
                backgroundColor: _C.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  FOOTER
// ══════════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final String code;
  const _Footer({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Text(
        _T.get(code, 'footer'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: _C.inkLight, fontSize: 12, height: 1.8),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SHARED SECTION WRAPPER
// ══════════════════════════════════════════════════════════════════
class _Section extends StatelessWidget {
  final String eyebrow, title;
  final String? subtitle;
  final Widget child;
  const _Section({required this.eyebrow, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Eyebrow
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 24, height: 2, color: _C.accent),
              const SizedBox(width: 8),
              Text(eyebrow.toUpperCase(), style: const TextStyle(color: _C.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
            ]),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: _C.inkDark, fontSize: 30, fontWeight: FontWeight.w900, height: 1.15)),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(subtitle!, style: const TextStyle(color: _C.inkLight, fontSize: 15, height: 1.7)),
            ],
            const SizedBox(height: 32),
            child,
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

