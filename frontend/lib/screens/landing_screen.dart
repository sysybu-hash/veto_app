// ============================================================
//  LandingScreen — VETO 2026
//  Pixel-aligned with design_mockups/2026/landing.html.
//
//  Sections (top → bottom):
//    1. Topbar (brand + nav + lang + login/signup)
//    2. Hero (eyebrow + headline + body + CTAs + proof points + mini-device)
//    3. Features (3 cards)
//    4. Stats (4 cells, 1px hairline grid)
//    5. Stack (1-2-3 numbered steps)
//    6. Pricing (badge + h2 + price + 5 bullets + CTA)
//    7. CTA strip (dark navy gradient + 2 buttons)
//    8. Footer
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_tokens_2026.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';

// ──────────────────────────────────────────────────────────
//  i18n (preserved from legacy landing_screen.dart)
// ──────────────────────────────────────────────────────────
class _T {
  static String get(String code, String key) =>
      (_copy[AppLanguage.normalize(code)] ?? _copy['he']!)[key] ?? key;

  static const _copy = <String, Map<String, String>>{
    'he': {
      'navHome':       'בית',
      'navFeatures':   'תכונות',
      'navPricing':    'תמחור',
      'navHow':        'איך זה עובד',
      'navContact':    'צור קשר',
      'navLogin':      'כניסה',
      'navRegister':   'הרשמה',
      'eyebrow':       'VETO · זמין 24/7 בכל הארץ',
      'heroTitle1':    'ההגנה המשפטית\nשלך — תמיד ',
      'heroTitleEm':   'בהישג יד',
      'heroBody':      'VETO מחבר אותך לעורך דין מתמחה תוך שניות בכל מצב חירום, עם תיעוד שיחה מלא, גיבוי בכספת אישית מוצפנת, ומסירת כל הראיות לידיך בלבד.',
      'heroCta':       'לחץ SOS עכשיו',
      'heroSecondary': 'איך זה עובד →',
      'proof1num':     '4.9',  'proof1lbl': '/5 דירוג ממשתמשים',
      'proof2num':     '3"',   'proof2lbl': 'זמן חיבור ממוצע',
      'proof3num':     '+200', 'proof3lbl': 'עורכי דין רשומים',
      'miniStat':      'חיבור ב-3 שניות',
      'feat1Title':    'הגנה מיידית',
      'feat1Body':     'חיבור לעורך דין מתמחה תוך שניות, בכל מצב חירום משפטי — חקירה במשטרה, עצירת תנועה, סכסוך אזרחי.',
      'feat2Title':    'קשר ישיר עם עו"ד',
      'feat2Body':     'קולי, וידאו או טקסט — הבחירה שלך. תיעוד שיחה מלא, נשמר אך ורק בכספת המוצפנת שלך.',
      'feat3Title':    'פרטיות מלאה',
      'feat3Body':     'הצפנה End-to-End, גיבוי בכספת אישית, וגישה רק לידיך — לא לחברה ולא לרשויות.',
      'stat1num': '24/7', 'stat1lbl': 'הגנה משפטית',
      'stat2num': 'Real', 'stat2lbl': 'עורכי דין אמיתיים',
      'stat3num': '+3',   'stat3lbl': 'שפות נתמכות',
      'stat4num': 'Live', 'stat4lbl': 'שיגור בזמן אמת',
      'stackKicker':   'איך זה עובד',
      'stackTitle':    'רצף תגובה אחד',
      'stack1Title':   'זיהוי מצב',
      'stack1Body':    'עוצרים, נחקרים, עצורים או מעורבים בתאונה? המערכת מתאימה מענה מיידי לסיטואציה הספציפית.',
      'stack2Title':   'שיחה עם AI',
      'stack2Body':    'הסוכן מסדר את הידע, מחדד שאלות, ומכוון לצעד המשפטי הבא בשפה שנוחה לך.',
      'stack3Title':   'חיבור אנושי',
      'stack3Body':    'אם נדרש עורך דין — המשרד מזניק איש מקצוע זמין עם עדיפות לשפה ולתחום הרלוונטי.',
      'pricingBadge':  'מנוי חודשי',
      'pricingTitle':  'שכבת הגנה תמידית',
      'pricingLede':   'השקיפו פעם אחת — וקבלו הגנה משפטית מלאה לכל השנה, בלי הפתעות.',
      'pricingPrice':  '₪19.90',
      'pricingPeriod': '/ לחודש',
      'pricingCta':    'התחל עכשיו →',
      'pricingLine1':  'עוזר AI משפטי ללא הגבלה — שאל כל שאלה, קבל תשובה מיידית.',
      'pricingLine2':  'תרחישים מותאמים — חקירה, תעבורה, אזרחי, עבודה, משפחה, צרכנות.',
      'pricingLine3':  'שיגור עורך דין באירוע חי — לפי שימוש, ללא תוספות נסתרות.',
      'pricingLine4':  'כספת מוצפנת — מסמכים, ראיות ושיחות, רק בידיך.',
      'pricingLine5':  'תמיכה בעברית, אנגלית ורוסית — 24/7.',
      'ctaTitle1':     'בונים שכבת הגנה',
      'ctaTitle2':     'לפני שהאירוע מתחיל',
      'ctaBody':       'ההרשמה קצרה. מהרגע שהיא מסתיימת, כל חירום משפטי מקבל מסך ברור ומוכן לפעולה.',
      'ctaBtn':        'לעבור לאשף',
      'ctaBtn2':       'דבר עם איש מכירות',
      'footerCopy':    'VETO LEGAL · מערכת תגובה משפטית חכמה, מהירה ורב-לשונית',
      'linkPrivacy':   'מדיניות פרטיות',
      'linkTerms':     'תנאי שימוש',
      'linkContact':   'צור קשר',
      'linkCareer':    'קריירה',
    },
    'en': {
      'navHome':       'Home', 'navFeatures': 'Features', 'navPricing': 'Pricing',
      'navHow':        'How it works', 'navContact': 'Contact',
      'navLogin':      'Sign in', 'navRegister': 'Sign up',
      'eyebrow':       'VETO · Available 24/7 nationwide',
      'heroTitle1':    'Your legal protection —\nalways ',
      'heroTitleEm':   'within reach',
      'heroBody':      'VETO connects you to a specialised lawyer within seconds in any emergency, with full call recording, encrypted personal vault, and evidence delivered only to you.',
      'heroCta':       'Press SOS now',
      'heroSecondary': 'How it works →',
      'proof1num':     '4.9',  'proof1lbl': '/5 user rating',
      'proof2num':     '3"',   'proof2lbl': 'average connect time',
      'proof3num':     '+200', 'proof3lbl': 'registered lawyers',
      'miniStat':      'Connect in 3 seconds',
      'feat1Title':    'Immediate protection',
      'feat1Body':     'Connect to a specialised lawyer in seconds — police interrogation, traffic stop, civil dispute.',
      'feat2Title':    'Direct lawyer contact',
      'feat2Body':     'Voice, video or text — your choice. Full recording, saved only to your encrypted vault.',
      'feat3Title':    'Full privacy',
      'feat3Body':     'End-to-end encryption, personal vault backup, access only to you — not us, not authorities.',
      'stat1num': '24/7', 'stat1lbl': 'Legal protection',
      'stat2num': 'Real', 'stat2lbl': 'Real lawyers',
      'stat3num': '+3',   'stat3lbl': 'Supported languages',
      'stat4num': 'Live', 'stat4lbl': 'Live dispatch',
      'stackKicker':   'How it works',
      'stackTitle':    'One response chain',
      'stack1Title':   'Situation detection',
      'stack1Body':    'Stopped, questioned, detained or in an accident? The system adapts instantly.',
      'stack2Title':   'Conversation with AI',
      'stack2Body':    'The assistant structures the facts, sharpens questions, and guides your next legal move.',
      'stack3Title':   'Human connection',
      'stack3Body':    'If a lawyer is needed, the platform dispatches one with language and specialty matching.',
      'pricingBadge':  'Monthly plan',
      'pricingTitle':  'Always-on protection',
      'pricingLede':   'Pay once — get full legal protection year-round, no surprises.',
      'pricingPrice':  '₪19.90',
      'pricingPeriod': '/ month',
      'pricingCta':    'Start now →',
      'pricingLine1':  'Unlimited legal AI assistant — ask anything, get instant answers.',
      'pricingLine2':  'Tailored scenarios — interrogation, traffic, civil, employment, family, consumer.',
      'pricingLine3':  'Live lawyer dispatch — billed by use, no hidden fees.',
      'pricingLine4':  'Encrypted vault — documents, evidence, calls, only in your hands.',
      'pricingLine5':  'Support in Hebrew, English & Russian — 24/7.',
      'ctaTitle1':     'Build your legal layer',
      'ctaTitle2':     'before the incident starts',
      'ctaBody':       'Registration is short. From the moment you finish, every legal emergency starts from one clear screen.',
      'ctaBtn':        'Open the wizard',
      'ctaBtn2':       'Talk to sales',
      'footerCopy':    'VETO LEGAL · Smart, fast, multilingual legal response',
      'linkPrivacy':   'Privacy', 'linkTerms': 'Terms',
      'linkContact':   'Contact', 'linkCareer': 'Careers',
    },
    'ru': {
      'navHome':       'Главная', 'navFeatures': 'Функции', 'navPricing': 'Тарифы',
      'navHow':        'Как это работает', 'navContact': 'Контакты',
      'navLogin':      'Вход', 'navRegister': 'Регистрация',
      'eyebrow':       'VETO · Доступно 24/7 по всей стране',
      'heroTitle1':    'Ваша юридическая защита —\nвсегда ',
      'heroTitleEm':   'под рукой',
      'heroBody':      'VETO соединяет вас со специализированным адвокатом за секунды, с полной записью разговора, зашифрованным хранилищем и передачей доказательств только вам.',
      'heroCta':       'Нажмите SOS',
      'heroSecondary': 'Как это работает →',
      'proof1num':     '4.9',  'proof1lbl': '/5 рейтинг',
      'proof2num':     '3"',   'proof2lbl': 'среднее время',
      'proof3num':     '+200', 'proof3lbl': 'адвокатов',
      'miniStat':      'Соединение за 3 секунды',
      'feat1Title':    'Мгновенная защита',
      'feat1Body':     'Соединение с адвокатом за секунды — допрос, остановка, гражданский спор.',
      'feat2Title':    'Прямой контакт',
      'feat2Body':     'Голос, видео, текст — на ваш выбор. Запись хранится в вашем шифрованном хранилище.',
      'feat3Title':    'Полная конфиденциальность',
      'feat3Body':     'E2E-шифрование, личное хранилище, доступ только у вас.',
      'stat1num': '24/7', 'stat1lbl': 'Защита',
      'stat2num': 'Real', 'stat2lbl': 'Живые адвокаты',
      'stat3num': '+3',   'stat3lbl': 'Языка',
      'stat4num': 'Live', 'stat4lbl': 'Живой вызов',
      'stackKicker':   'Как это работает',
      'stackTitle':    'Одна цепочка реакции',
      'stack1Title':   'Определение ситуации',
      'stack1Body':    'Остановка, допрос, задержание, ДТП? Система мгновенно адаптируется.',
      'stack2Title':   'Беседа с AI',
      'stack2Body':    'Помощник структурирует факты и направляет к следующему шагу.',
      'stack3Title':   'Связь с человеком',
      'stack3Body':    'При необходимости платформа вызывает адвоката с учётом языка и специализации.',
      'pricingBadge':  'Ежемесячный план',
      'pricingTitle':  'Постоянная защита',
      'pricingLede':   'Оплатите один раз — получите полную защиту на весь год.',
      'pricingPrice':  '₪19.90',
      'pricingPeriod': '/ в месяц',
      'pricingCta':    'Начать →',
      'pricingLine1':  'Безлимитный юридический AI.',
      'pricingLine2':  'Сценарии: допрос, дорога, гражданский, труд, семья, потребитель.',
      'pricingLine3':  'Вызов адвоката — по факту использования.',
      'pricingLine4':  'Зашифрованное хранилище — только у вас.',
      'pricingLine5':  'Поддержка на иврите, английском и русском — 24/7.',
      'ctaTitle1':     'Создайте защитный слой',
      'ctaTitle2':     'до начала инцидента',
      'ctaBody':       'Регистрация занимает минуту. После — любой инцидент начинается с одного экрана.',
      'ctaBtn':        'Перейти к мастеру',
      'ctaBtn2':       'Поговорить с продажами',
      'footerCopy':    'VETO LEGAL · Быстрая, умная и мультиязычная юридическая реакция',
      'linkPrivacy':   'Конфиденциальность', 'linkTerms': 'Условия',
      'linkContact':   'Контакты',           'linkCareer': 'Карьера',
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

    String t(String k) => _T.get(code, k);

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        body: SafeArea(
          child: Column(
            children: [
              _Topbar(compact: compact, onLogin: () => _goNext(context), t: t),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Hero(compact: compact, onSos: () => _goNext(context), onSecondary: () {}, t: t),
                      _Features(compact: compact, t: t),
                      _Stats(compact: compact, t: t),
                      _Stack(compact: compact, t: t),
                      _Pricing(compact: compact, onCta: () => _goNext(context), t: t),
                      _CtaStrip(compact: compact, onCta: () => _goNext(context), t: t),
                      _Footer(compact: compact, t: t),
                    ],
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

// ──────────────────────────────────────────────────────────
//  Topbar
// ──────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  const _Topbar({required this.compact, required this.onLogin, required this.t});
  final bool compact;
  final VoidCallback onLogin;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 28, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: VetoTokens.hairline, width: 1)),
      ),
      child: Row(
        children: [
          // Brand
          const _Crest(size: 34),
          const SizedBox(width: 10),
          Text(
            'VETO',
            style: VetoTokens.serif(18, FontWeight.w900, color: VetoTokens.ink900, letterSpacing: 0.36),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              'הגנה משפטית מיידית',
              style: VetoTokens.sans(12, FontWeight.w500, color: VetoTokens.navy600, letterSpacing: 1.92),
            ),
          ],
          const Spacer(),
          if (!compact) ...[
            _NavLink(t('navHome'), active: true),
            _NavLink(t('navFeatures')),
            _NavLink(t('navPricing')),
            _NavLink(t('navHow')),
            _NavLink(t('navContact')),
            const SizedBox(width: 14),
          ],
          // Lang pill
          const AppLanguageMenu(compact: true),
          const SizedBox(width: 8),
          // Sign in (ghost)
          _GhostButton(label: t('navLogin'), onPressed: onLogin),
          const SizedBox(width: 8),
          // Sign up (primary)
          _PrimaryButton(label: t('navRegister'), onPressed: onLogin),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink(this.label, {this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: active ? VetoTokens.navy600 : VetoTokens.ink700,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: VetoTokens.sans(14, FontWeight.w600, color: active ? VetoTokens.navy600 : VetoTokens.ink700)),
            if (active)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: VetoTokens.navy500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Hero
// ──────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({required this.compact, required this.onSos, required this.onSecondary, required this.t});
  final bool compact;
  final VoidCallback onSos;
  final VoidCallback onSecondary;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EyebrowPill(label: t('eyebrow')),
        const SizedBox(height: 18),
        // Headline: "..." + Em(...) — em coloured navy600 with gold underline.
        RichText(
          text: TextSpan(
            style: VetoTokens.serif(
              compact ? 34 : 64,
              FontWeight.w800,
              color: VetoTokens.ink900,
              height: 1.05,
              letterSpacing: -1.0,
            ),
            children: [
              TextSpan(text: t('heroTitle1')),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: _GoldUnderline(
                  text: t('heroTitleEm'),
                  fontSize: compact ? 34 : 64,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 540,
          child: Text(
            t('heroBody'),
            style: VetoTokens.sans(compact ? 14 : 17, FontWeight.w500, color: VetoTokens.ink500, height: 1.65),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DangerButton(label: t('heroCta'), onPressed: onSos, lg: true),
            _GhostButton(label: t('heroSecondary'), onPressed: onSecondary, lg: true),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.only(top: 18),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: VetoTokens.hairline, width: 1)),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _Proof(num: t('proof1num'), label: t('proof1lbl')),
              _Proof(num: t('proof2num'), label: t('proof2lbl')),
              if (!compact) _Proof(num: t('proof3num'), label: t('proof3lbl')),
            ],
          ),
        ),
      ],
    );

    final right = _HeroVisual(miniStat: t('miniStat'));

    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 56, compact ? 24 : 64, compact ? 20 : 56, compact ? 28 : 44),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.84, -1.0),
          radius: 1.2,
          colors: [Color(0x1A2E69E7), Color(0x002E69E7)],
        ),
      ),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 24), right])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 21, child: left),
                const SizedBox(width: 48),
                Expanded(flex: 19, child: right),
              ],
            ),
    );
  }
}

class _EyebrowPill extends StatelessWidget {
  const _EyebrowPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(VetoTokens.rPill),
        border: Border.all(color: VetoTokens.hairline, width: 1),
        boxShadow: VetoTokens.shadow1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: VetoTokens.ok,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x2E2BA374), blurRadius: 0, spreadRadius: 3)],
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: VetoTokens.sans(11, FontWeight.w800, color: VetoTokens.navy600, letterSpacing: 1.98)),
        ],
      ),
    );
  }
}

class _GoldUnderline extends StatelessWidget {
  const _GoldUnderline({required this.text, required this.fontSize});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: fontSize * 0.18,
          child: Container(
            height: fontSize * 0.12,
            decoration: BoxDecoration(
              color: VetoTokens.goldSoft.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Text(
          text,
          style: VetoTokens.serif(
            fontSize, FontWeight.w800,
            color: VetoTokens.navy600, height: 1.05, letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }
}

class _Proof extends StatelessWidget {
  const _Proof({required this.num, required this.label});
  // ignore: avoid_field_initializers_in_const_classes
  final String num;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(num, style: VetoTokens.serif(24, FontWeight.w800, color: VetoTokens.ink900, height: 1.0)),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(label, style: VetoTokens.sans(11, FontWeight.w500, color: VetoTokens.ink500, height: 1.3)),
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.miniStat});
  final String miniStat;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [VetoTokens.navy500.withValues(alpha: 0.10), Colors.transparent],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // Mini phone
          FractionallySizedBox(
            widthFactor: 0.78,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1830),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(color: Color(0x380B1830), blurRadius: 80, offset: Offset(0, 30)),
                    BoxShadow(color: Color(0x1F0B1830), blurRadius: 24, offset: Offset(0, 8)),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: VetoTokens.paper,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: VetoTokens.sosOrbGradient,
                          boxShadow: VetoTokens.shadowEmerg,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'SOS',
                          style: VetoTokens.serif(30, FontWeight.w900, color: Colors.white, letterSpacing: 5.4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(miniStat, style: VetoTokens.sans(11, FontWeight.w500, color: VetoTokens.ink500)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Features
// ──────────────────────────────────────────────────────────
class _Features extends StatelessWidget {
  const _Features({required this.compact, required this.t});
  final bool compact;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _FeatureCard(
        iconBuilder: (c) => const Icon(Icons.flash_on_rounded, size: 22, color: VetoTokens.navy700),
        title: t('feat1Title'),
        body: t('feat1Body'),
      ),
      _FeatureCard(
        iconBuilder: (c) => const Icon(Icons.chat_bubble_outline_rounded, size: 22, color: VetoTokens.navy700),
        title: t('feat2Title'),
        body: t('feat2Body'),
      ),
      _FeatureCard(
        iconBuilder: (c) => const Icon(Icons.lock_outline_rounded, size: 22, color: VetoTokens.navy700),
        title: t('feat3Title'),
        body: t('feat3Body'),
      ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 56, 32, compact ? 20 : 56, 0),
      child: compact
          ? Column(children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i < cards.length - 1) const SizedBox(height: 12),
              ]
            ])
          : Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 18),
                ]
              ],
            ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.iconBuilder, required this.title, required this.body});
  final WidgetBuilder iconBuilder;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: VetoTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.white, VetoTokens.navy100],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VetoTokens.hairline, width: 1),
              boxShadow: VetoTokens.shadow1,
            ),
            alignment: Alignment.center,
            child: iconBuilder(context),
          ),
          const SizedBox(height: 14),
          Text(title, style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900)),
          const SizedBox(height: 6),
          Text(body, style: VetoTokens.sans(13.5, FontWeight.w500, color: VetoTokens.ink500, height: 1.55)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Stats — 1px hairline grid, 2 or 4 cells
// ──────────────────────────────────────────────────────────
class _Stats extends StatelessWidget {
  const _Stats({required this.compact, required this.t});
  final bool compact;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final cells = [
      _StatCell(num: t('stat1num'), label: t('stat1lbl')),
      _StatCell(num: t('stat2num'), label: t('stat2lbl')),
      _StatCell(num: t('stat3num'), label: t('stat3lbl')),
      _StatCell(num: t('stat4num'), label: t('stat4lbl')),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 56, 24, compact ? 20 : 56, 0),
      child: Container(
        decoration: BoxDecoration(
          color: VetoTokens.hairline,
          border: Border.all(color: VetoTokens.hairline, width: 1),
          borderRadius: BorderRadius.circular(VetoTokens.rLg),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VetoTokens.rLg),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: compact ? 2 : 4,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            childAspectRatio: compact ? 2.2 : 2.6,
            children: cells,
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.num, required this.label});
  // ignore: avoid_field_initializers_in_const_classes
  final String num;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(num, style: VetoTokens.serif(32, FontWeight.w800, color: VetoTokens.ink900, height: 1.0)),
          const SizedBox(height: 8),
          Text(label, style: VetoTokens.sans(11, FontWeight.w500, color: VetoTokens.ink500, letterSpacing: 0.66)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Stack 1-2-3
// ──────────────────────────────────────────────────────────
class _Stack extends StatelessWidget {
  const _Stack({required this.compact, required this.t});
  final bool compact;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StackStep(num: '01', title: t('stack1Title'), body: t('stack1Body')),
      _StackStep(num: '02', title: t('stack2Title'), body: t('stack2Body')),
      _StackStep(num: '03', title: t('stack3Title'), body: t('stack3Body')),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 56, 24, compact ? 20 : 56, 0),
      child: Container(
        padding: EdgeInsets.all(compact ? 24 : 48),
        decoration: VetoTokens.liftCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(t('stackKicker'), style: VetoTokens.kicker),
            const SizedBox(height: 12),
            Text(
              t('stackTitle'),
              textAlign: TextAlign.center,
              style: VetoTokens.serif(compact ? 24 : 36, FontWeight.w700, color: VetoTokens.ink900, letterSpacing: -0.7),
            ),
            const SizedBox(height: 32),
            if (compact)
              Column(children: [for (var s in steps) ...[s, const SizedBox(height: 18)]])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < steps.length; i++) ...[
                    Expanded(child: steps[i]),
                    if (i < steps.length - 1) const SizedBox(width: 24),
                  ]
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StackStep extends StatelessWidget {
  const _StackStep({required this.num, required this.title, required this.body});
  // ignore: avoid_field_initializers_in_const_classes
  final String num;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          num,
          style: VetoTokens.serif(54, FontWeight.w900, color: VetoTokens.navy600.withValues(alpha: 0.16), height: 1.0),
        ),
        const SizedBox(height: 10),
        Text(title, style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900)),
        const SizedBox(height: 6),
        Text(body, style: VetoTokens.sans(13.5, FontWeight.w500, color: VetoTokens.ink500, height: 1.6)),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Pricing
// ──────────────────────────────────────────────────────────
class _Pricing extends StatelessWidget {
  const _Pricing({required this.compact, required this.onCta, required this.t});
  final bool compact;
  final VoidCallback onCta;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Badge.brand(t('pricingBadge')),
        const SizedBox(height: 10),
        Text(
          t('pricingTitle'),
          style: VetoTokens.serif(compact ? 28 : 38, FontWeight.w700, color: VetoTokens.ink900, height: 1.15),
        ),
        const SizedBox(height: 6),
        Text(t('pricingLede'), style: VetoTokens.sans(14, FontWeight.w500, color: VetoTokens.ink500, height: 1.6)),
        const SizedBox(height: 14),
        Row(
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            Text(t('pricingPrice'),
                style: VetoTokens.serif(54, FontWeight.w900, color: VetoTokens.navy600, height: 1.0)),
            const SizedBox(width: 6),
            Text(t('pricingPeriod'), style: VetoTokens.sans(14, FontWeight.w600, color: VetoTokens.ink500)),
          ],
        ),
        const SizedBox(height: 18),
        _PrimaryButton(label: t('pricingCta'), onPressed: onCta, lg: true),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PriceLine(t('pricingLine1')),
        _PriceLine(t('pricingLine2')),
        _PriceLine(t('pricingLine3')),
        _PriceLine(t('pricingLine4')),
        _PriceLine(t('pricingLine5')),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 56, 32, compact ? 20 : 56, 0),
      child: Container(
        padding: EdgeInsets.all(compact ? 24 : 48),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.white, VetoTokens.surface2],
          ),
          borderRadius: BorderRadius.circular(VetoTokens.r2Xl),
          border: Border.all(color: VetoTokens.hairline, width: 1),
          boxShadow: VetoTokens.shadow2,
        ),
        child: compact
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 24), right])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 10, child: left),
                  const SizedBox(width: 32),
                  Expanded(flex: 12, child: right),
                ],
              ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: VetoTokens.okSoft,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF16664B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: VetoTokens.sans(14, FontWeight.w500, color: VetoTokens.ink700, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  CTA Strip (dark navy gradient + gold radial)
// ──────────────────────────────────────────────────────────
class _CtaStrip extends StatelessWidget {
  const _CtaStrip({required this.compact, required this.onCta, required this.t});
  final bool compact;
  final VoidCallback onCta;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 56, 24, compact ? 20 : 56, 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 24 : 56, vertical: compact ? 24 : 48),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VetoTokens.r2Xl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [VetoTokens.navy700, VetoTokens.navy600],
          ),
        ),
        child: Stack(
          children: [
            // Gold radial accent (top-end)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(VetoTokens.r2Xl),
                    gradient: const RadialGradient(
                      center: Alignment(0.9, -0.6),
                      radius: 0.7,
                      colors: [Color(0x33B8895C), Color(0x00B8895C)],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t('ctaTitle1')}\n${t('ctaTitle2')}',
                  style: VetoTokens.serif(compact ? 24 : 36, FontWeight.w700, color: Colors.white, height: 1.15),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 520,
                  child: Text(
                    t('ctaBody'),
                    style: VetoTokens.sans(14, FontWeight.w500, color: const Color(0xFFC7D5EE), height: 1.6),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    _GoldButton(label: t('ctaBtn'), onPressed: onCta, lg: true),
                    if (!compact) _OutlineWhiteButton(label: t('ctaBtn2'), onPressed: () {}, lg: true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  Footer
// ──────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({required this.compact, required this.t});
  final bool compact;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 56, 32, compact ? 20 : 56, 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: VetoTokens.hairline, width: 1)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('footerCopy'), style: VetoTokens.sans(12, FontWeight.w500, color: VetoTokens.ink500)),
                const SizedBox(height: 10),
                _footerLinks(t),
              ],
            )
          : Row(
              children: [
                Text(t('footerCopy'), style: VetoTokens.sans(12, FontWeight.w500, color: VetoTokens.ink500)),
                const Spacer(),
                _footerLinks(t),
              ],
            ),
    );
  }

  Widget _footerLinks(String Function(String) t) => Wrap(
        spacing: 18,
        children: [
          _footerLink(t('linkPrivacy'), '/privacy'),
          _footerLink(t('linkTerms'), '/terms'),
          _footerLink(t('linkContact'), null),
          _footerLink(t('linkCareer'), null),
        ],
      );

  Widget _footerLink(String label, String? route) => Builder(
        builder: (ctx) => InkWell(
          onTap: route == null ? null : () => Navigator.pushNamed(ctx, route),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(label, style: VetoTokens.sans(12, FontWeight.w600, color: VetoTokens.ink500)),
          ),
        ),
      );
}

// ──────────────────────────────────────────────────────────
//  Shared atomic widgets — buttons, badges, crest
// ──────────────────────────────────────────────────────────
class _Crest extends StatelessWidget {
  const _Crest({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: VetoTokens.crestGradient,
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: const [BoxShadow(color: Color(0x59264975), blurRadius: 14, offset: Offset(0, 6))],
        border: Border.all(color: const Color(0x1FFFFFFF), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        'V',
        style: VetoTokens.serif(size * 0.44, FontWeight.w900, color: Colors.white, height: 1.0, letterSpacing: size * 0.018),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.lg = false});
  final String label;
  final VoidCallback onPressed;
  final bool lg;

  @override
  Widget build(BuildContext context) {
    final h = lg ? 48.0 : 38.0;
    return Container(
      height: h,
      decoration: BoxDecoration(
        boxShadow: VetoTokens.shadowBrand,
        borderRadius: BorderRadius.circular(lg ? 12 : 10),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: VetoTokens.navy600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: lg ? 22 : 16),
          minimumSize: Size(0, h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(lg ? 12 : 10)),
          textStyle: lg ? VetoTokens.labelLg : VetoTokens.labelMd,
        ),
        child: Text(label),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed, this.lg = false});
  final String label;
  final VoidCallback onPressed;
  final bool lg;

  @override
  Widget build(BuildContext context) {
    final h = lg ? 48.0 : 38.0;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: VetoTokens.navy600,
        backgroundColor: Colors.white,
        side: const BorderSide(color: VetoTokens.navy300, width: 1),
        padding: EdgeInsets.symmetric(horizontal: lg ? 22 : 14),
        minimumSize: Size(0, h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(lg ? 12 : 10)),
        textStyle: lg ? VetoTokens.labelLg : VetoTokens.labelMd,
      ),
      child: Text(label),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onPressed, this.lg = false});
  final String label;
  final VoidCallback onPressed;
  final bool lg;

  @override
  Widget build(BuildContext context) {
    final h = lg ? 48.0 : 38.0;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x4DD6243A), blurRadius: 16, offset: Offset(0, 6))],
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: VetoTokens.emerg,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: lg ? 22 : 16),
          minimumSize: Size(0, h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(lg ? 12 : 10)),
          textStyle: lg ? VetoTokens.labelLg : VetoTokens.labelMd,
        ),
        child: Text(label),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onPressed, this.lg = false});
  final String label;
  final VoidCallback onPressed;
  final bool lg;

  @override
  Widget build(BuildContext context) {
    final h = lg ? 48.0 : 38.0;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x52B8895C), blurRadius: 16, offset: Offset(0, 6))],
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: VetoTokens.gold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: lg ? 22 : 16),
          minimumSize: Size(0, h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(lg ? 12 : 10)),
          textStyle: lg ? VetoTokens.labelLg : VetoTokens.labelMd,
        ),
        child: Text(label),
      ),
    );
  }
}

class _OutlineWhiteButton extends StatelessWidget {
  const _OutlineWhiteButton({required this.label, required this.onPressed, this.lg = false});
  final String label;
  final VoidCallback onPressed;
  final bool lg;

  @override
  Widget build(BuildContext context) {
    final h = lg ? 48.0 : 38.0;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1),
        padding: EdgeInsets.symmetric(horizontal: lg ? 22 : 14),
        minimumSize: Size(0, h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(lg ? 12 : 10)),
        textStyle: lg ? VetoTokens.labelLg : VetoTokens.labelMd,
      ),
      child: Text(label),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge.brand(this.label) : color = VetoTokens.infoSoft, fg = VetoTokens.navy700, border = const Color(0xFFC4D4F4);
  final String label;
  final Color color;
  final Color fg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(VetoTokens.rPill),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(label, style: VetoTokens.sans(11, FontWeight.w700, color: fg)),
    );
  }
}
