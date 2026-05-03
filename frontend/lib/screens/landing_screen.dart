// ═══════════════════════════════════════════════════════════════════
//  VETO Landing — 2026 Light Professional-Luxury
//  Navy + Gold + Paper, serif headlines, gold micro-rule
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_2026_splash.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';
import '../widgets/accessibility_toolbar.dart';
import '../widgets/ai_chat_dialog.dart';

// ── Palette — 2026 Navy / Gold / Paper ─────────────────────────────
class _C {
  static const bg = V26.paper;
  static const navBg = V26.surface;
  static const inkDark = V26.ink900;
  static const inkMid = V26.ink700;
  static const inkLight = V26.ink500;
  static const accent = V26.navy600;
}

// ── i18n ──────────────────────────────────────────────────────────
class _T {
  static String get(String code, String k) =>
      (_copy[AppLanguage.normalize(code)] ?? _copy['he']!)[k] ?? k;

  static const _copy = <String, Map<String, String>>{
    'he': {
      'navHome': 'בית',
      'navFeatures': 'תכונות',
      'navPricing': 'תמחור',
      'navContact': 'צור קשר',
      'navLogin': 'כניסה',
      'navRegister': 'הרשמה',
      'heroEyebrow': 'זמין 24/7',
      'heroTitleL1': 'ההגנה המשפטית',
      'heroTitleL2': 'שלך — תמיד ',
      'heroTitleEm': 'בהישג יד',
      'heroBody':
          'VETO מחבר אותך לעורך דין מתמחה תוך שניות בכל מצב חירום, עם תיעוד שיחה מלא וכספת מוצפנת.',
      'heroCta': 'לחץ SOS',
      'heroSecondary': 'גלה עוד',
      'miniStatBefore': 'חיבור ב-',
      'miniStatEm': '3 שניות',
      'proof1Num': '4.9',
      'proof1Lbl': 'דירוג ממשתמשים',
      'proof2Num': '3″',
      'proof2Lbl': 'זמן חיבור ממוצע',
      'feat1Title': 'הגנה מיידית',
      'feat1Body':
          'חיבור לעורך דין מתמחה תוך שניות, בכל מצב חירום משפטי — חקירה, עצירה, סכסוך.',
      'feat2Title': 'קשר ישיר עם עו"ד',
      'feat2Body':
          'קולי, וידאו או טקסט — הבחירה שלך. תיעוד שיחה מלא, נשמר אך ורק בכספת המוצפנת שלך.',
      'feat3Title': 'פרטיות מלאה',
      'feat3Body':
          'הצפנה End-to-End, גיבוי בכספת אישית, וגישה רק לידיך — לא לחברה ולא לרשויות.',
      'statTitle': 'למה VETO?',
      'stat1num': '24/7',
      'stat1lbl': 'הגנה משפטית',
      'stat2num': 'Real',
      'stat2lbl': 'עורכי דין אמיתיים',
      'stat3num': '+3',
      'stat3lbl': 'שפות נתמכות',
      'stat4num': 'Live',
      'stat4lbl': 'שיגור בזמן אמת',
      'stackTitle': 'רצף תגובה אחד',
      'stackKicker': 'איך זה עובד',
      'stack1Title': 'זיהוי מצב',
      'stack1Body':
          'נחקרים, עצורים, או מעורבים בתאונה? המערכת מתאימה מענה מיידי.',
      'stack2Title': 'שיחה עם AI',
      'stack2Body': 'הסוכן מסדר את הידע, מחדד שאלות, ומכוון לצעד המשפטי הבא.',
      'stack3Title': 'חיבור אנושי',
      'stack3Body':
          'אם נדרש עו"ד — המשרד מזניק איש מקצוע זמין עם עדיפות לשפה הרלוונטית.',
      'pricingTitle': 'מנוי חודשי',
      'pricingHeroTitle': 'שכבת הגנה תמידית',
      'pricingPrice': '₪19.90',
      'pricingPeriod': 'לחודש',
      'pricingLine1': 'עוזר AI משפטי ללא הגבלה',
      'pricingLine2': 'תרחישים, זכויות ותיעוד ראיות',
      'pricingLine3': 'שיגור עורך דין באירוע חי לפי שימוש',
      'pricingLine4': 'כספת מוצפנת לשמירת מסמכים',
      'ctaTitle': 'בונים שכבת הגנה לפני שהאירוע מתחיל',
      'ctaBody':
          'ההרשמה קצרה. מהרגע שהיא מסתיימת, כל חירום משפטי מקבל מסך ברור ומוכן לפעולה.',
      'ctaBtn': 'לעבור לאשף',
      'footer': 'VETO LEGAL | מערכת תגובה משפטית חכמה, מהירה ורב-לשונית',
      'linkPrivacy': 'מדיניות פרטיות',
      'linkTerms': 'תנאי שימוש',
    },
    'en': {
      'navHome': 'Home',
      'navFeatures': 'Features',
      'navPricing': 'Pricing',
      'navContact': 'Contact',
      'navLogin': 'Sign in',
      'navRegister': 'Sign up',
      'heroEyebrow': 'Available 24/7',
      'heroTitleL1': 'Your legal protection',
      'heroTitleL2': ' — always ',
      'heroTitleEm': 'within reach',
      'heroBody':
          'VETO connects you with a specialized lawyer within seconds in any emergency — full conversation logging and an encrypted vault.',
      'heroCta': 'SOS',
      'heroSecondary': 'Learn more',
      'miniStatBefore': 'Connect in ',
      'miniStatEm': '3 seconds',
      'proof1Num': '4.9',
      'proof1Lbl': 'User rating',
      'proof2Num': '3″',
      'proof2Lbl': 'Avg. connect time',
      'feat1Title': 'Immediate protection',
      'feat1Body':
          'Connect with a specialized lawyer within seconds — investigations, detention, disputes.',
      'feat2Title': 'Direct lawyer access',
      'feat2Body':
          'Voice, video, or text — your choice. Full call logs stored only in your encrypted vault.',
      'feat3Title': 'Full privacy',
      'feat3Body':
          'End-to-end encryption, backup in your vault, access only for you — not the company or authorities.',
      'statTitle': 'Why VETO?',
      'stat1num': '24/7',
      'stat1lbl': 'Legal Protection',
      'stat2num': 'Real',
      'stat2lbl': 'Lawyers',
      'stat3num': '+3',
      'stat3lbl': 'Languages',
      'stat4num': 'Live',
      'stat4lbl': 'Dispatch',
      'stackTitle': 'One response chain',
      'stackKicker': 'How it works',
      'stack1Title': 'Situation awareness',
      'stack1Body':
          'Questioned, detained, or in an accident? The system responds immediately.',
      'stack2Title': 'AI conversation',
      'stack2Body':
          'The agent organizes facts, sharpens questions, and guides your next legal step.',
      'stack3Title': 'Human handoff',
      'stack3Body':
          'When a lawyer is required — dispatch with priority for the right language.',
      'pricingTitle': 'Monthly Plan',
      'pricingHeroTitle': 'Always-on protection layer',
      'pricingPrice': '₪19.90',
      'pricingPeriod': 'per month',
      'pricingLine1': 'Unlimited legal AI assistant',
      'pricingLine2': 'Rights scenarios and evidence tools',
      'pricingLine3': 'Live lawyer dispatch billed by event',
      'pricingLine4': 'Encrypted vault for your documents',
      'ctaTitle': 'Build your legal safety layer before the incident begins',
      'ctaBody':
          'Registration is short. Once done, every legal emergency starts from one clear interface.',
      'ctaBtn': 'Open the wizard',
      'footer': 'VETO LEGAL | Fast, intelligent, multilingual legal response',
      'linkPrivacy': 'Privacy',
      'linkTerms': 'Terms',
    },
    'ru': {
      'navHome': 'Главная',
      'navFeatures': 'Функции',
      'navPricing': 'Тарифы',
      'navContact': 'Контакты',
      'navLogin': 'Вход',
      'navRegister': 'Регистрация',
      'heroEyebrow': 'Доступно 24/7',
      'heroTitleL1': 'Ваша юридическая защита',
      'heroTitleL2': ' — всегда ',
      'heroTitleEm': 'рядом',
      'heroBody':
          'VETO соединяет вас со специализированным адвокатом за секунды в любой экстренной ситуации — полное журналирование и зашифрованное хранилище.',
      'heroCta': 'SOS',
      'heroSecondary': 'Узнать больше',
      'miniStatBefore': 'Подключение за ',
      'miniStatEm': '3 секунды',
      'proof1Num': '4.9',
      'proof1Lbl': 'Оценка пользователей',
      'proof2Num': '3″',
      'proof2Lbl': 'Среднее время связи',
      'feat1Title': 'Мгновенная защита',
      'feat1Body':
          'Связь со специализированным адвокатом за секунды — допрос, задержание, конфликт.',
      'feat2Title': 'Прямой контакт с адвокатом',
      'feat2Body':
          'Голос, видео или текст — как удобно. Полные логи только в вашем зашифрованном хранилище.',
      'feat3Title': 'Полная конфиденциальность',
      'feat3Body':
          'Сквозное шифрование, резерв в хранилище, доступ только у вас — не у компании и не у органов.',
      'statTitle': 'Почему VETO?',
      'stat1num': '24/7',
      'stat1lbl': 'Защита',
      'stat2num': 'Живые',
      'stat2lbl': 'Адвокаты',
      'stat3num': '+3',
      'stat3lbl': 'Языка',
      'stat4num': 'Живой',
      'stat4lbl': 'Вызов',
      'stackTitle': 'Одна цепочка реакции',
      'stackKicker': 'Как это работает',
      'stack1Title': 'Определение ситуации',
      'stack1Body':
          'Допрос, задержание или ДТП? Система сразу подбирает ответ.',
      'stack2Title': 'Диалог с AI',
      'stack2Body':
          'Агент структурирует факты, уточняет вопросы и ведёт к следующему шагу.',
      'stack3Title': 'Связь с человеком',
      'stack3Body':
          'Если нужен адвокат — оперативный вызов с приоритетом языка.',
      'pricingTitle': 'Ежемесячный план',
      'pricingHeroTitle': 'Постоянная защита',
      'pricingPrice': '₪19.90',
      'pricingPeriod': 'в месяц',
      'pricingLine1': 'Безлимитный юридический AI',
      'pricingLine2': 'Сценарии прав и сбор доказательств',
      'pricingLine3': 'Вызов адвоката по событию',
      'pricingLine4': 'Зашифрованное хранилище документов',
      'ctaTitle': 'Создайте защитный слой до начала инцидента',
      'ctaBody':
          'Регистрация занимает минуту. После этого любая экстренная ситуация начинается с одного экрана.',
      'ctaBtn': 'Перейти к мастеру',
      'footer':
          'VETO LEGAL | Быстрая, умная и мультиязычная юридическая реакция',
      'linkPrivacy': 'Конфиденциальность',
      'linkTerms': 'Условия',
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
    final code = context.watch<AppLanguageController>().code;
    final dir = AppLanguage.directionOf(code);
    final w = MediaQuery.of(context).size.width;
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
          backgroundColor: V26.navy600,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(
            code == 'he'
                ? 'שאל את VETO AI'
                : code == 'ru'
                    ? 'Спросить VETO AI'
                    : 'Ask VETO AI',
            style: const TextStyle(
              fontFamily: V26.sans,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: V26Backdrop(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavBar(
                    code: code,
                    compact: compact,
                    onTap: () => _goNext(context)),
                _HeroSection(
                    code: code,
                    compact: compact,
                    onTap: () => _goNext(context)),
                _FeaturesSection(code: code, compact: compact),
                _StatsBar(code: code, compact: compact),
                _StackSection(code: code, compact: compact),
                _PricingSection(
                    code: code,
                    compact: compact,
                    onTap: () => _goNext(context)),
                _CtaSection(
                    code: code,
                    compact: compact,
                    onTap: () => _goNext(context)),
                _Footer(code: code),
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
  final String code;
  final bool compact;
  final VoidCallback onTap;
  const _NavBar(
      {required this.code, required this.compact, required this.onTap});

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

  void _enterApp(BuildContext ctx) {
    if (_role == 'lawyer') {
      Navigator.pushNamed(ctx, '/lawyer_dashboard');
    } else if (_role == 'admin') {
      Navigator.pushNamed(ctx, '/admin_settings');
    } else {
      Navigator.pushNamed(ctx, '/veto_screen');
    }
  }

  void _showCompactNav(BuildContext context, List<String> navItemLabels) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: V26.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final label in navItemLabels)
              ListTile(
                title: Text(label,
                    style: const TextStyle(
                        color: _C.inkDark, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onTap();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const t = _T.get;
    final c = widget.code;
    final navItems = <String>[
      t(c, 'navHome'),
      t(c, 'navFeatures'),
      t(c, 'navPricing'),
      t(c, 'navContact'),
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
                const SizedBox(width: 6),
                Text(
                  (c == 'he'
                      ? 'LEGAL'
                      : c == 'ru'
                          ? 'LEGAL'
                          : 'LEGAL'),
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.navy600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.6,
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
              ],

              const Spacer(),

              // ── Desktop: language then accessibility (keeps a11y off the outer edge in RTL Web)
              if (!widget.compact) const AppLanguageMenu(compact: true),
              // ── Mobile: hamburger then accessibility (ליד כפתור התפריט), then language
              if (widget.compact)
                IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      color: _C.inkMid, size: 22),
                  onPressed: () => _showCompactNav(context, navItems),
                  tooltip: kIsWeb
                      ? null
                      : (c == 'he'
                          ? 'תפריט'
                          : c == 'ru'
                              ? 'Меню'
                              : 'Menu'),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              IconButton(
                icon: Icon(
                  Icons.accessibility_new_rounded,
                  color: _C.inkMid,
                  size: 20,
                  semanticLabel: kIsWeb
                      ? (c == 'he'
                          ? 'נגישות'
                          : c == 'ru'
                              ? 'Доступность'
                              : 'Accessibility')
                      : null,
                ),
                onPressed: () => showAccessibilitySheet(context),
                tooltip: kIsWeb
                    ? null
                    : (c == 'he'
                        ? 'נגישות'
                        : c == 'ru'
                            ? 'Доступность'
                            : 'Accessibility'),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              if (widget.compact) const AppLanguageMenu(compact: true),
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
                _NavBtn(
                    label: t(c, 'navLogin'),
                    filled: false,
                    onTap: widget.onTap),
                const SizedBox(width: 8),
                _NavBtn(
                    label: t(c, 'navRegister'),
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
  final String code;
  final VoidCallback onEnterApp;

  const _UserBubble({
    required this.name,
    required this.role,
    required this.code,
    required this.onEnterApp,
  });

  String get _initial =>
      (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : '?';

  String _roleLabel(String? r) {
    switch (r) {
      case 'lawyer':
        return code == 'he'
            ? 'עו"ד'
            : code == 'ru'
                ? 'Адвокат'
                : 'Lawyer';
      case 'admin':
        return code == 'he'
            ? 'מנהל'
            : code == 'ru'
                ? 'Админ'
                : 'Admin';
      default:
        return code == 'he'
            ? 'משתמש'
            : code == 'ru'
                ? 'Польз.'
                : 'User';
    }
  }

  Color get _roleColor {
    switch (role) {
      case 'lawyer':
        return V26.gold;
      case 'admin':
        return V26.navy800;
      default:
        return V26.navy600;
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
                  name ?? (code == 'he' ? 'משתמש' : 'User'),
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
                color: V26.navy600, size: 12),
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
  final String code;
  final bool compact;
  final VoidCallback onTap;
  const _HeroSection(
      {required this.code, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const t = _T.get;
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
          TextSpan(text: t(code, 'miniStatBefore')),
          TextSpan(
            text: t(code, 'miniStatEm'),
            style: const TextStyle(
              color: V26.ink900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );

    final textBlock = _HeroCopyColumn(
      code: code,
      compact: compact,
      titleSize: titleSize,
      onTap: onTap,
    );

    final mini = V26LandingMiniDevice(caption: caption);

    return Container(
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
    );
  }
}

class _HeroCopyColumn extends StatelessWidget {
  final String code;
  final bool compact;
  final double titleSize;
  final VoidCallback onTap;
  const _HeroCopyColumn({
    required this.code,
    required this.compact,
    required this.titleSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const t = _T.get;
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
                t(code, 'heroEyebrow'),
                style: const TextStyle(
                  fontFamily: V26.sans,
                  color: V26.navy600,
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
          t(code, 'heroTitleL1'),
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
              t(code, 'heroTitleL2'),
              style: TextStyle(
                fontFamily: V26.serif,
                color: V26.ink900,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.02 * titleSize,
              ),
            ),
            _HeroEmphasis(text: t(code, 'heroTitleEm'), size: titleSize),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          t(code, 'heroBody'),
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
              t(code, 'heroCta'),
              onPressed: onTap,
              variant: V26CtaVariant.danger,
              large: true,
              icon: Icons.warning_amber_rounded,
            ),
            V26CTA(
              t(code, 'heroSecondary'),
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
                numeral: t(code, 'proof1Num'),
                label: t(code, 'proof1Lbl'),
              ),
              _LandingProofPair(
                numeral: t(code, 'proof2Num'),
                label: t(code, 'proof2Lbl'),
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
            color: V26.navy600,
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
  final String code;
  final bool compact;
  const _StatsBar({required this.code, required this.compact});

  @override
  Widget build(BuildContext context) {
    const t = _T.get;
    final stats = [
      (t(code, 'stat1num'), t(code, 'stat1lbl')),
      (t(code, 'stat2num'), t(code, 'stat2lbl')),
      (t(code, 'stat3num'), t(code, 'stat3lbl')),
      (t(code, 'stat4num'), t(code, 'stat4lbl')),
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
  final String code;
  final bool compact;
  const _StackSection({required this.code, required this.compact});

  @override
  Widget build(BuildContext context) {
    const t = _T.get;
    final steps = [
      ('01', t(code, 'stack1Title'), t(code, 'stack1Body')),
      ('02', t(code, 'stack2Title'), t(code, 'stack2Body')),
      ('03', t(code, 'stack3Title'), t(code, 'stack3Body')),
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
                Center(child: V26Kicker(t(code, 'stackKicker'))),
                const SizedBox(height: 8),
                Text(
                  t(code, 'stackTitle'),
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
            color: V26.navy600.withValues(alpha: 0.16),
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
  final String code;
  final bool compact;
  const _FeaturesSection({required this.code, required this.compact});

  @override
  Widget build(BuildContext context) {
    const t = _T.get;
    final features = [
      (
        Icons.bolt_rounded,
        V26.navy700,
        t(code, 'feat1Title'),
        t(code, 'feat1Body')
      ),
      (
        Icons.chat_bubble_rounded,
        V26.navy600,
        t(code, 'feat2Title'),
        t(code, 'feat2Body')
      ),
      (Icons.lock_rounded, V26.ok, t(code, 'feat3Title'), t(code, 'feat3Body')),
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
  final String code;
  final bool compact;
  final VoidCallback onTap;
  const _PricingSection(
      {required this.code, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const t = _T.get;
    final lines = <String>[
      t(code, 'pricingLine1'),
      t(code, 'pricingLine2'),
      t(code, 'pricingLine3'),
      t(code, 'pricingLine4'),
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
        V26Badge(t(code, 'pricingTitle'), tone: V26BadgeTone.brand),
        const SizedBox(height: 12),
        Text(
          t(code, 'pricingHeroTitle'),
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
              t(code, 'pricingPrice'),
              style: const TextStyle(
                fontFamily: V26.serif,
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: V26.navy600,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              t(code, 'pricingPeriod'),
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: V26.ink500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        V26CTA(
          code == 'he'
              ? 'התחל עכשיו'
              : code == 'ru'
                  ? 'Начать'
                  : 'Get started',
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
  final String code;
  final bool compact;
  final VoidCallback onTap;
  const _CtaSection(
      {required this.code, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const t = _T.get;
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
                  colors: [V26.navy700, V26.navy600],
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
                          t(code, 'ctaTitle'),
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
                          t(code, 'ctaBody'),
                          style: const TextStyle(
                            fontFamily: V26.sans,
                            color: Color(0xFFC7D5EE),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        V26CTA(
                          t(code, 'ctaBtn'),
                          onPressed: onTap,
                          variant: V26CtaVariant.gold,
                          large: true,
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
  final String code;
  const _Footer({required this.code});

  @override
  Widget build(BuildContext context) {
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
            _T.get(code, 'footer'),
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: _C.inkLight, fontSize: 12, height: 1.8),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/privacy'),
                child: Text(
                  _T.get(code, 'linkPrivacy'),
                  style: const TextStyle(
                    color: _C.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: _C.accent,
                  ),
                ),
              ),
              Text(' · ',
                  style: TextStyle(color: _C.inkLight.withValues(alpha: 0.5))),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/terms'),
                child: Text(
                  _T.get(code, 'linkTerms'),
                  style: const TextStyle(
                    color: _C.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: _C.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

