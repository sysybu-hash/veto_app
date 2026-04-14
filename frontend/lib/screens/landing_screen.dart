import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';

// ═══════════════════════════════════════════════════════════════════
//  VETO Landing Page — Attorney Shield aesthetic
//  Dark, dramatic, high-contrast. No logic changes.
// ═══════════════════════════════════════════════════════════════════

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // ── Translations ─────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _copy = {
    'he': {
      'navLogin': 'כניסה',
      'navCta': 'פתיחת חשבון',
      'heroBadge': 'מערכת תגובה משפטית חכמה ורב-לשונית',
      'heroTitle': 'במצב לחץ\nלא מחפשים עזרה.\nפותחים את VETO.',
      'heroBody': 'מערכת אחת שמחברת עוזר AI, תרחישי זכויות, תיעוד ראיות ושיגור עורך דין לזמן אמת.',
      'heroPrimary': 'התחל באשף',
      'heroSecondary': 'כניסה מהירה',
      'proof1': 'AI משפטי בכל רגע',
      'proof2': 'עברית · English · Русский',
      'proof3': 'שיגור עורך דין רק כשצריך',
      'stackTitle': 'רצף תגובה אחד',
      'stack1Title': 'זיהוי מצב',
      'stack1Body': 'עוצרים, נחקרים, נעצרים או מעורבים בתאונה? המערכת מתאימה מענה מיידי לסיטואציה.',
      'stack2Title': 'שיחה עם AI',
      'stack2Body': 'הסוכן מסדר את המידע, מחדד שאלות, ומכוון לצעד המשפטי הבא בשפה שנוחה לך.',
      'stack3Title': 'חיבור אנושי',
      'stack3Body': 'אם צריך עורך דין, המערכת מזניקה איש מקצוע זמין עם עדיפות לשפה הרלוונטית.',
      'sectionSignals': 'למה זה מרגיש אחרת',
      'signalsTitle': 'מוצר שנבנה לרגע שבו אין זמן לקרוא אותיות קטנות',
      'signal1Title': 'הנחיות חדות ולא תיאורטיות',
      'signal1Body': 'במקום הסברים כלליים, מקבלים פעולות קצרות וברורות לפי סיטואציה משפטית חיה.',
      'signal2Title': 'שכבת AI שלא נשארת לבד',
      'signal2Body': 'העוזר החכם פותח את האירוע, אבל המערכת יודעת מתי להעביר לידיים אנושיות.',
      'signal3Title': 'ראיות, מיקום והקשר במקום אחד',
      'signal3Body': 'כל פרט חשוב נשמר באותו מהלך, בלי לפצל בין אפליקציות, צילומים ושיחות.',
      'sectionFlow': 'איך זה עובד',
      'flowTitle': 'מסלול קצר מהכניסה עד תגובה מבצעית',
      'flow1Title': 'בחירת תפקיד ושפה',
      'flow1Body': 'האשף מגדיר אם אתה אזרח, עורך דין או מנהל, ושומר את שפת העבודה שלך להמשך.',
      'flow2Title': 'אימות מהיר',
      'flow2Body': 'אחרי OTP, כל תפקיד מגיע ישירות למסך הייעודי שלו בלי ניווט צדדי מבלבל.',
      'flow3Title': 'עבודה שוטפת או חירום מיידי',
      'flow3Body': 'אפשר להמשיך עם AI, לבחור תרחיש, לתעד ראיות או להפעיל SOS ולהזניק תגובה אנושית.',
      'sectionAudience': 'למי זה מיועד',
      'audienceTitle': 'פלטפורמה אחת, שלושה סוגי משתמשים, שפה עיצובית אחת',
      'audience1Title': 'אזרחים',
      'audience1Body': 'למי שצריך להבין מהר מה מותר, מה לא לומר, ואיך לשמור על זכויות בזמן אמת.',
      'audience2Title': 'עורכי דין',
      'audience2Body': 'עמדת תגובה עם שליטה בזמינות, תיבת קריאות חיה, וקבלת תיקים מתוך אירועים פעילים.',
      'audience3Title': 'ניהול ותפעול',
      'audience3Body': 'ניהול משתמשים, אישורי עורכי דין, ניטור אירועי חירום והגדרות מערכת במקום אחד.',
      'sectionPricing': 'מודל שימוש פשוט',
      'pricingTitle': 'מנוי ברור. תגובה אנושית רק כשבאמת מסלימים.',
      'pricingBody': 'המנוי פותח את שכבת ה-AI, התרחישים והכלים. עורך דין חירום מופעל רק כאשר בוחרים לעבור לאירוע חי.',
      'planName': 'מנוי חודשי',
      'planPrice': '₪19.90',
      'planPeriod': 'לחודש',
      'planLine1': 'עוזר AI משפטי ללא הגבלה',
      'planLine2': 'תרחישים, זכויות ותיעוד ראיות',
      'planLine3': 'שיגור עורך דין באירוע חי לפי שימוש',
      'ctaBadge': 'מוכן לצאת לדרך?',
      'ctaTitle': 'בונים שכבת הגנה לפני שהאירוע מתחיל',
      'ctaBody': 'ההרשמה קצרה. מהרגע שהיא מסתיימת, כל חירום משפטי מקבל מסך ברור ומוכן לפעולה.',
      'ctaButton': 'לעבור לאשף',
      'footer': 'VETO LEGAL | מערכת תגובה משפטית חכמה, מהירה ורב-לשונית',
    },
    'en': {
      'navLogin': 'Sign in',
      'navCta': 'Create account',
      'heroBadge': 'Smart, human, multilingual legal response',
      'heroTitle': 'In a high-pressure\nmoment, you do not\nsearch. You open VETO.',
      'heroBody': 'One system that combines an AI legal assistant, rights scenarios, evidence capture, and real-time lawyer dispatch.',
      'heroPrimary': 'Start the wizard',
      'heroSecondary': 'Quick sign in',
      'proof1': 'Legal AI whenever you need it',
      'proof2': 'Hebrew · English · Russian',
      'proof3': 'Live lawyer dispatch only when needed',
      'stackTitle': 'One response chain',
      'stack1Title': 'Situation detection',
      'stack1Body': 'Stopped, questioned, detained, or in an accident? The flow adapts immediately to the legal scenario.',
      'stack2Title': 'AI conversation',
      'stack2Body': 'The assistant structures facts, sharpens the right questions, and points to the next legal move in your language.',
      'stack3Title': 'Human escalation',
      'stack3Body': 'If a lawyer is needed, the platform dispatches an available professional with language-aware matching.',
      'sectionSignals': 'Why it feels different',
      'signalsTitle': 'Built for the moment when there is no time to read fine print',
      'signal1Title': 'Actionable guidance, not vague theory',
      'signal1Body': 'Instead of generic explanations, users get short, clear actions tied to a real legal situation.',
      'signal2Title': 'An AI layer that does not stay alone',
      'signal2Body': 'The assistant opens the case, but the system knows when to move from software to human response.',
      'signal3Title': 'Evidence, location, and context in one place',
      'signal3Body': 'Every important signal stays inside the same flow instead of being scattered across chats, photos, and notes.',
      'sectionFlow': 'How it works',
      'flowTitle': 'A short path from onboarding to operational response',
      'flow1Title': 'Choose role and language',
      'flow1Body': 'The wizard defines whether you are a citizen, lawyer, or admin, and stores your working language.',
      'flow2Title': 'Verify quickly',
      'flow2Body': 'After OTP, each role goes straight to its dedicated screen without confusing side navigation.',
      'flow3Title': 'Work normally or escalate',
      'flow3Body': 'Continue with AI, choose a scenario, capture evidence, or trigger SOS for a live legal response.',
      'sectionAudience': 'Who it serves',
      'audienceTitle': 'One platform, three user types, one visual system',
      'audience1Title': 'Citizens',
      'audience1Body': 'For people who need to know what to say, what not to say, and how to protect their rights in real time.',
      'audience2Title': 'Lawyers',
      'audience2Body': 'A live response console with availability control, request inbox, and case acceptance from active events.',
      'audience3Title': 'Operations',
      'audience3Body': 'User management, lawyer approvals, emergency visibility, and system configuration in one place.',
      'sectionPricing': 'Simple usage model',
      'pricingTitle': 'Clear membership. Human escalation only when it is truly needed.',
      'pricingBody': 'The membership unlocks AI, scenarios, and evidence tools. Emergency lawyer dispatch activates only when a live event is escalated.',
      'planName': 'Monthly membership',
      'planPrice': '₪19.90',
      'planPeriod': 'per month',
      'planLine1': 'Unlimited legal AI assistant',
      'planLine2': 'Rights scenarios and evidence tools',
      'planLine3': 'Live lawyer dispatch billed by event',
      'ctaBadge': 'Ready to get started?',
      'ctaTitle': 'Build your legal safety layer before the incident begins',
      'ctaBody': 'Registration is short. Once it is done, every legal emergency starts from one clear, ready-to-use interface.',
      'ctaButton': 'Open the wizard',
      'footer': 'VETO LEGAL | Fast, intelligent, multilingual legal response',
    },
    'ru': {
      'navLogin': 'Вход',
      'navCta': 'Создать аккаунт',
      'heroBadge': 'Умная и мультиязычная юридическая реакция',
      'heroTitle': 'В момент давления\nне ищут помощь.\nОткрывают VETO.',
      'heroBody': 'Единая система, которая соединяет юридический AI, сценарии прав, фиксацию доказательств и вызов адвоката в реальном времени.',
      'heroPrimary': 'Открыть мастер',
      'heroSecondary': 'Быстрый вход',
      'proof1': 'Юридический AI в любой момент',
      'proof2': 'Иврит · English · Русский',
      'proof3': 'Вызов адвоката только при необходимости',
      'stackTitle': 'Одна цепочка реакции',
      'stack1Title': 'Определение ситуации',
      'stack1Body': 'Остановка, допрос, задержание или ДТП? Система сразу подстраивает поток под конкретный юридический сценарий.',
      'stack2Title': 'Диалог с AI',
      'stack2Body': 'Помощник структурирует факты, уточняет ключевые вопросы и ведет к следующему юридическому шагу на вашем языке.',
      'stack3Title': 'Подключение человека',
      'stack3Body': 'Если нужен адвокат, платформа вызывает свободного специалиста с учетом языка и контекста дела.',
      'sectionSignals': 'Почему это ощущается иначе',
      'signalsTitle': 'Система для момента, когда нет времени читать мелкий шрифт',
      'signal1Title': 'Четкие действия вместо размытой теории',
      'signal1Body': 'Пользователь получает короткие и практичные шаги, привязанные к реальной юридической ситуации.',
      'signal2Title': 'AI, который не остается один',
      'signal2Body': 'Помощник открывает кейс, но платформа знает, когда нужно перевести ситуацию к человеку.',
      'signal3Title': 'Доказательства, локация и контекст в одном месте',
      'signal3Body': 'Все важные сигналы хранятся в одном процессе, а не разбросаны по чатам, фото и заметкам.',
      'sectionFlow': 'Как это работает',
      'flowTitle': 'Короткий путь от входа к рабочей реакции',
      'flow1Title': 'Выбор роли и языка',
      'flow1Body': 'Мастер определяет, кто вы: гражданин, адвокат или администратор, и сохраняет рабочий язык.',
      'flow2Title': 'Быстрая проверка',
      'flow2Body': 'После OTP каждая роль попадает прямо на свой экран без лишней навигации.',
      'flow3Title': 'Обычная работа или эскалация',
      'flow3Body': 'Можно продолжить с AI, выбрать сценарий, зафиксировать доказательства или запустить SOS.',
      'sectionAudience': 'Для кого это',
      'audienceTitle': 'Одна платформа, три типа пользователей, единый визуальный язык',
      'audience1Title': 'Граждане',
      'audience1Body': 'Для тех, кому нужно быстро понять, что говорить, чего не говорить и как защитить свои права в реальном времени.',
      'audience2Title': 'Адвокаты',
      'audience2Body': 'Живая панель с управлением доступностью, входящими запросами и принятием дел из активных событий.',
      'audience3Title': 'Операции',
      'audience3Body': 'Управление пользователями, одобрением адвокатов, видимостью экстренных событий и системными настройками.',
      'sectionPricing': 'Простая модель использования',
      'pricingTitle': 'Понятная подписка. Живое подключение только когда это действительно нужно.',
      'pricingBody': 'Подписка открывает AI, сценарии и инструменты фиксации. Вызов адвоката активируется только при переходе к живому событию.',
      'planName': 'Ежемесячная подписка',
      'planPrice': '₪19.90',
      'planPeriod': 'в месяц',
      'planLine1': 'Безлимитный юридический AI',
      'planLine2': 'Сценарии прав и сбор доказательств',
      'planLine3': 'Вызов адвоката оплачивается по событию',
      'ctaBadge': 'Готовы начать?',
      'ctaTitle': 'Создайте юридический слой защиты до начала инцидента',
      'ctaBody': 'Регистрация занимает минимум времени. После нее любое ЧП начинается с одного понятного рабочего экрана.',
      'ctaButton': 'Перейти к мастеру',
      'footer': 'VETO LEGAL | Быстрая, умная и мультиязычная юридическая реакция',
    },
  };

  String _t(String code, String key) =>
      _copy[AppLanguage.normalize(code)]?[key] ??
      _copy[AppLanguage.hebrew]![key] ??
      key;

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
    final dir  = AppLanguage.directionOf(code);
    final w    = MediaQuery.of(context).size.width;
    final compact = w < 960;

    final stackItems = [
      _ItemData(icon: Icons.explore_outlined,              accent: VetoPalette.primary,   step: '01', title: _t(code, 'stack1Title'), body: _t(code, 'stack1Body')),
      _ItemData(icon: Icons.auto_awesome_outlined,         accent: VetoPalette.info,       step: '02', title: _t(code, 'stack2Title'), body: _t(code, 'stack2Body')),
      _ItemData(icon: Icons.notifications_active_outlined, accent: VetoPalette.success,    step: '03', title: _t(code, 'stack3Title'), body: _t(code, 'stack3Body')),
    ];
    final signalItems = [
      _ItemData(icon: Icons.rule_folder_outlined,  accent: VetoPalette.primary,   title: _t(code, 'signal1Title'), body: _t(code, 'signal1Body')),
      _ItemData(icon: Icons.smart_toy_outlined,    accent: VetoPalette.info,       title: _t(code, 'signal2Title'), body: _t(code, 'signal2Body')),
      _ItemData(icon: Icons.perm_media_outlined,   accent: VetoPalette.warning,    title: _t(code, 'signal3Title'), body: _t(code, 'signal3Body')),
    ];
    final flowItems = [
      _ItemData(icon: Icons.language_rounded,       accent: VetoPalette.primary,   step: '01', title: _t(code, 'flow1Title'), body: _t(code, 'flow1Body')),
      _ItemData(icon: Icons.verified_user_outlined, accent: VetoPalette.success,    step: '02', title: _t(code, 'flow2Title'), body: _t(code, 'flow2Body')),
      _ItemData(icon: Icons.crisis_alert_rounded,   accent: VetoPalette.emergency,  step: '03', title: _t(code, 'flow3Title'), body: _t(code, 'flow3Body')),
    ];
    final audienceItems = [
      _ItemData(icon: Icons.person_search_outlined,        accent: VetoPalette.primary,   title: _t(code, 'audience1Title'), body: _t(code, 'audience1Body')),
      _ItemData(icon: Icons.gavel_rounded,                 accent: VetoPalette.success,    title: _t(code, 'audience2Title'), body: _t(code, 'audience2Body')),
      _ItemData(icon: Icons.admin_panel_settings_outlined, accent: VetoPalette.warning,    title: _t(code, 'audience3Title'), body: _t(code, 'audience3Body')),
    ];

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: _Clr.bg,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── NAV ──────────────────────────────────────────────────
              _Nav(code: code, loginLabel: _t(code, 'navLogin'), ctaLabel: _t(code, 'navCta'), onTap: () => _goNext(context)),

              // ── HERO ─────────────────────────────────────────────────
              _HeroSection(
                badge:          _t(code, 'heroBadge'),
                title:          _t(code, 'heroTitle'),
                body:           _t(code, 'heroBody'),
                primaryLabel:   _t(code, 'heroPrimary'),
                secondaryLabel: _t(code, 'heroSecondary'),
                proof1: _t(code, 'proof1'),
                proof2: _t(code, 'proof2'),
                proof3: _t(code, 'proof3'),
                stackTitle: _t(code, 'stackTitle'),
                stackItems: stackItems,
                compact: compact,
                onTap: () => _goNext(context),
              ),

              // ── STAT BAR ─────────────────────────────────────────────
              _StatBar(),

              // ── INCIDENTS (4 use-case cards, attorney-shield style) ────
              _IncidentsSection(compact: compact, code: code),

              // ── SIGNALS ──────────────────────────────────────────────
              _ContentSection(
                eyebrow: _t(code, 'sectionSignals'),
                title:   _t(code, 'signalsTitle'),
                child:   _CardGrid(items: signalItems, compact: compact),
              ),

              // ── FLOW ─────────────────────────────────────────────────
              _ContentSection(
                eyebrow: _t(code, 'sectionFlow'),
                title:   _t(code, 'flowTitle'),
                child:   _FlowGrid(items: flowItems, compact: compact),
              ),

              // ── AUDIENCE ─────────────────────────────────────────────
              _ContentSection(
                eyebrow: _t(code, 'sectionAudience'),
                title:   _t(code, 'audienceTitle'),
                child:   _CardGrid(items: audienceItems, compact: compact),
              ),

              // ── PRICING ──────────────────────────────────────────────
              _ContentSection(
                eyebrow:  _t(code, 'sectionPricing'),
                title:    _t(code, 'pricingTitle'),
                subtitle: _t(code, 'pricingBody'),
                child: _PricingCard(
                  planName: _t(code, 'planName'),
                  price:    _t(code, 'planPrice'),
                  period:   _t(code, 'planPeriod'),
                  lines: [_t(code, 'planLine1'), _t(code, 'planLine2'), _t(code, 'planLine3')],
                  buttonLabel: _t(code, 'heroPrimary'),
                  compact: compact,
                  onTap: () => _goNext(context),
                ),
              ),

              // ── TESTIMONIALS ─────────────────────────────────────────
              _TestimonialsSection(compact: compact, code: code),

              // ── CTA ───────────────────────────────────────────────────
              _CtaSection(
                badge:       _t(code, 'ctaBadge'),
                title:       _t(code, 'ctaTitle'),
                body:        _t(code, 'ctaBody'),
                buttonLabel: _t(code, 'ctaButton'),
                compact: compact,
                onTap: () => _goNext(context),
              ),

              // ── FOOTER ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                child: Text(_t(code, 'footer'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _Clr.muted, fontSize: 12, height: 1.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Color palette
// ═══════════════════════════════════════════════════════════════════
class _Clr {
  static const bg         = Color(0xFFF8FAFC);
  static const surface    = Color(0xFFFFFFFF);
  static const card       = Color(0xFFF0F9FF);
  static const border     = Color(0x330D9488);
  static const heroBg     = Color(0xFFFFFFFF);
  static const heroBg2    = Color(0xFFE8F4FC);
  static const heroBorder = Color(0x440D9488);
  static const glow       = Color(0xFF0D9488);
  static const muted      = Color(0xFF64748B);
  static const sub        = Color(0xFF0F172A);
  static const navInk    = Color(0xFF334155);
}

// ═══════════════════════════════════════════════════════════════════
//  Data model
// ═══════════════════════════════════════════════════════════════════
class _ItemData {
  final IconData icon;
  final Color accent;
  final String? step;
  final String title;
  final String body;
  const _ItemData({required this.icon, required this.accent, this.step, required this.title, required this.body});
}

// ═══════════════════════════════════════════════════════════════════
//  NAV
// ═══════════════════════════════════════════════════════════════════
class _Nav extends StatefulWidget {
  final String loginLabel, ctaLabel, code;
  final VoidCallback onTap;
  const _Nav({required this.loginLabel, required this.ctaLabel, required this.code, required this.onTap});

  @override
  State<_Nav> createState() => _NavState();
}

class _NavState extends State<_Nav> {
  bool _loggedIn = false;
  String? _role;

  static const _menuLabels = {
    'he': ['תמחור', 'איך זה עובד', 'לעורכי דין', 'אודות'],
    'en': ['Pricing', 'How It Works', 'For Lawyers', 'About'],
    'ru': ['Тарифы', 'Как работает', 'Адвокатам', 'О нас'],
  };
  static const _enterAppLabel = {
    'he': 'כניסה לאפליקציה',
    'en': 'Enter App',
    'ru': 'Войти в приложение',
  };

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await AuthService().getToken();
    if (token != null && token.isNotEmpty) {
      final role = await AuthService().getStoredRole();
      if (mounted) setState(() { _loggedIn = true; _role = role; });
    }
  }

  void _enterApp(BuildContext context) {
    if (_loggedIn) {
      if (_role == 'lawyer') {
        Navigator.pushNamed(context, '/lawyer_dashboard');
      } else if (_role == 'admin') {
        Navigator.pushNamed(context, '/admin_settings');
      } else {
        Navigator.pushNamed(context, '/veto_screen');
      }
    } else {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.code;
    final menuItems = _menuLabels[c] ?? _menuLabels['en']!;
    final enterLabel = _enterAppLabel[c] ?? _enterAppLabel['en']!;
    final wide = MediaQuery.of(context).size.width > 860;

    return Container(
      decoration: const BoxDecoration(
        color: _Clr.heroBg,
        border: Border(bottom: BorderSide(color: _Clr.heroBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(children: [
            // Logo
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 17), // on gold chip
            ),
            const SizedBox(width: 10),
            const Text('VETO v7.0', style: TextStyle(color: _Clr.sub, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 5)),
            const Text(' LEGAL', style: TextStyle(color: _Clr.glow, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2)),
            if (wide) ...[
              const SizedBox(width: 28),
              for (final item in menuItems)
                TextButton(
                  onPressed: widget.onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: _Clr.navInk,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(48, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
            ],
            const Spacer(),
            const AppLanguageMenu(compact: true),
            const SizedBox(width: 8),
            if (_loggedIn)
              FilledButton.icon(
                onPressed: () => _enterApp(context),
                icon: const Icon(Icons.apps_rounded, size: 15),
                label: Text(enterLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              )
            else ...[
              TextButton(
                onPressed: widget.onTap,
                style: TextButton.styleFrom(
                  foregroundColor: _Clr.navInk,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  minimumSize: const Size(48, 40),
                ),
                child: Text(widget.loginLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              _PrimaryBtn(label: widget.ctaLabel, onTap: widget.onTap),
            ],
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HERO SECTION — full-bleed, dramatic
// ═══════════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final String badge, title, body, primaryLabel, secondaryLabel;
  final String proof1, proof2, proof3;
  final String stackTitle;
  final List<_ItemData> stackItems;
  final bool compact;
  final VoidCallback onTap;

  const _HeroSection({
    required this.badge, required this.title, required this.body,
    required this.primaryLabel, required this.secondaryLabel,
    required this.proof1, required this.proof2, required this.proof3,
    required this.stackTitle, required this.stackItems,
    required this.compact, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_Clr.heroBg, _Clr.heroBg2, _Clr.heroBg],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border(bottom: BorderSide(color: _Clr.heroBorder)),
      ),
      child: Stack(
        children: [
          // Decorative glow blob
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_Clr.glow.withValues(alpha: 0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(28, compact ? 48 : 64, 28, compact ? 48 : 64),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: compact
                    ? Column(children: [
                        _HeroContent(
                          badge: badge, title: title, body: body,
                          primaryLabel: primaryLabel, secondaryLabel: secondaryLabel,
                          proof1: proof1, proof2: proof2, proof3: proof3,
                          compact: compact, onTap: onTap,
                        ),
                        const SizedBox(height: 32),
                        _StackRail(title: stackTitle, items: stackItems),
                      ])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 12, child: _HeroContent(
                            badge: badge, title: title, body: body,
                            primaryLabel: primaryLabel, secondaryLabel: secondaryLabel,
                            proof1: proof1, proof2: proof2, proof3: proof3,
                            compact: compact, onTap: onTap,
                          )),
                          const SizedBox(width: 24),
                          Expanded(flex: 8, child: _StackRail(title: stackTitle, items: stackItems)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  final String badge, title, body, primaryLabel, secondaryLabel, proof1, proof2, proof3;
  final bool compact;
  final VoidCallback onTap;
  const _HeroContent({
    required this.badge, required this.title, required this.body,
    required this.primaryLabel, required this.secondaryLabel,
    required this.proof1, required this.proof2, required this.proof3,
    required this.compact, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: VetoPalette.primary.withValues(alpha: 0.1),
          border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 5, height: 5,
              decoration: const BoxDecoration(color: VetoPalette.primary, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(badge, style: const TextStyle(
            color: VetoPalette.info, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3,
          )),
        ]),
      ),
      SizedBox(height: compact ? 20 : 24),

      // Title — massive, dramatic
      Text(title,
        style: TextStyle(
          color: VetoColors.white,
          fontSize: compact ? 38 : 64,
          fontWeight: FontWeight.w900,
          height: 1.04,
          letterSpacing: -1.2,
        ),
      ),
      SizedBox(height: compact ? 16 : 20),

      // Blue accent line
      Container(
        height: 3, width: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [VetoPalette.primary, Colors.transparent]),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 20),

      // Body
      Text(body, style: const TextStyle(color: _Clr.sub, fontSize: 16, height: 1.8)),
      const SizedBox(height: 32),

      // CTAs
      Wrap(spacing: 12, runSpacing: 12, children: [
        _PrimaryBtn(label: primaryLabel, onTap: onTap, large: true),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.login_rounded, size: 16),
          label: Text(secondaryLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: _Clr.sub,
            side: const BorderSide(color: _Clr.heroBorder, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
      const SizedBox(height: 32),

      // Divider
      const Divider(color: _Clr.heroBorder, height: 1),
      const SizedBox(height: 20),

      // Proof pills
      Wrap(spacing: 8, runSpacing: 8, children: [
        _ProofChip(label: proof1),
        _ProofChip(label: proof2),
        _ProofChip(label: proof3),
      ]),
    ]);
  }
}

class _StackRail extends StatelessWidget {
  final String title;
  final List<_ItemData> items;
  const _StackRail({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Clr.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Clr.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(children: [
            Container(width: 3, height: 18, color: VetoPalette.primary),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(
              color: Color(0xFF07101C), fontSize: 16, fontWeight: FontWeight.w800,
            )),
          ]),
        ),
        // Items
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: _Clr.border, indent: 0, endIndent: 0),
          _StackItem(data: items[i]),
        ],
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _StackItem extends StatelessWidget {
  final _ItemData data;
  const _StackItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: data.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(data.icon, color: data.accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.title, style: const TextStyle(
            color: Color(0xFF07101C), fontSize: 14, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 4),
          Text(data.body, style: const TextStyle(
            color: _Clr.muted, fontSize: 12, height: 1.65,
          )),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STAT BAR — three quick numbers between hero and sections
// ═══════════════════════════════════════════════════════════════════
class _StatBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const stats = [
      ('24/7', 'Legal Protection'),
      ('3+',   'Languages'),
      ('Real', 'Lawyers'),
      ('Live', 'Dispatch'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF07101C),
        border: Border.symmetric(horizontal: BorderSide(color: _Clr.heroBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var (num, label) in stats) ...[
                Column(children: [
                  Text(num, style: const TextStyle(
                    color: Color(0xFF0D9488), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1,
                  )),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(color: Color(0xFFA8A090), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CONTENT SECTION (eyebrow + title + child)
// ═══════════════════════════════════════════════════════════════════
class _ContentSection extends StatelessWidget {
  final String eyebrow, title;
  final String? subtitle;
  final Widget child;
  const _ContentSection({required this.eyebrow, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Eyebrow
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 28, height: 1.5, color: VetoPalette.primary),
              const SizedBox(width: 10),
              Text(eyebrow.toUpperCase(), style: const TextStyle(
                color: VetoPalette.primary, fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 3,
              )),
            ]),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(
              color: Color(0xFF07101C), fontSize: 36, fontWeight: FontWeight.w900, height: 1.1,
            )),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(subtitle!, style: const TextStyle(
                color: _Clr.muted, fontSize: 15, height: 1.8, fontWeight: FontWeight.w400,
              )),
            ],
            const SizedBox(height: 36),
            child,
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CARD GRID — 3 columns (row) or stack on mobile
// ═══════════════════════════════════════════════════════════════════
class _CardGrid extends StatelessWidget {
  final List<_ItemData> items;
  final bool compact;
  const _CardGrid({required this.items, required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(children: [
        for (var i = 0; i < items.length; i++) ...[
          _FeatureCard(data: items[i]),
          if (i < items.length - 1) const SizedBox(height: 10),
        ],
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < items.length; i++) ...[
        Expanded(child: _FeatureCard(data: items[i])),
        if (i < items.length - 1) const SizedBox(width: 10),
      ],
    ]);
  }
}

class _FeatureCard extends StatelessWidget {
  final _ItemData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Clr.card,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left:   BorderSide(color: data.accent, width: 3),
          top:    const BorderSide(color: _Clr.border),
          right:  const BorderSide(color: _Clr.border),
          bottom: const BorderSide(color: _Clr.border),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: data.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(data.icon, color: data.accent, size: 22),
        ),
        const SizedBox(height: 16),
        Text(data.title, style: const TextStyle(
          color: Color(0xFF07101C), fontSize: 16, fontWeight: FontWeight.w800,
        )),
        const SizedBox(height: 8),
        Text(data.body, style: const TextStyle(
          color: _Clr.muted, fontSize: 13, height: 1.75,
        )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FLOW GRID — numbered steps with connecting line on desktop
// ═══════════════════════════════════════════════════════════════════
class _FlowGrid extends StatelessWidget {
  final List<_ItemData> items;
  final bool compact;
  const _FlowGrid({required this.items, required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(children: [
        for (var i = 0; i < items.length; i++) ...[
          _FlowCard(data: items[i], isLast: i == items.length - 1),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < items.length; i++) ...[
        Expanded(child: _FlowCard(data: items[i], isLast: i == items.length - 1)),
        if (i < items.length - 1) ...[
          const SizedBox(width: 0),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Container(width: 32, height: 1.5,
                color: _Clr.border.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 0),
        ],
      ],
    ]);
  }
}

class _FlowCard extends StatelessWidget {
  final _ItemData data;
  final bool isLast;
  const _FlowCard({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Clr.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Clr.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Step number
        Text(data.step ?? '', style: TextStyle(
          color: data.accent, fontSize: 36, fontWeight: FontWeight.w900,
          letterSpacing: -2, height: 1,
        )),
        const SizedBox(height: 14),
        Row(children: [
          Icon(data.icon, color: data.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(data.title, style: const TextStyle(
            color: Color(0xFF07101C), fontSize: 15, fontWeight: FontWeight.w800,
          ))),
        ]),
        const SizedBox(height: 8),
        Text(data.body, style: const TextStyle(
          color: _Clr.muted, fontSize: 13, height: 1.75,
        )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PRICING CARD
// ═══════════════════════════════════════════════════════════════════
class _PricingCard extends StatelessWidget {
  final String planName, price, period, buttonLabel;
  final List<String> lines;
  final bool compact;
  final VoidCallback onTap;
  const _PricingCard({
    required this.planName, required this.price, required this.period,
    required this.lines, required this.buttonLabel,
    required this.compact, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _Clr.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.4), width: 1.5),
        gradient: LinearGradient(
          colors: [
            VetoPalette.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _priceBlock(),
              const SizedBox(height: 24),
              ..._featureLines(),
              const SizedBox(height: 24),
              _ctaButton(),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _priceBlock(),
              const SizedBox(width: 52),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: _featureLines())),
              const SizedBox(width: 36),
              _ctaButton(),
            ]),
    );
    return inner;
  }

  Widget _priceBlock() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(planName.toUpperCase(), style: const TextStyle(
        color: VetoPalette.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3,
      )),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(price, style: const TextStyle(
          color: Color(0xFF07101C), fontSize: 58, fontWeight: FontWeight.w900, height: 1,
        )),
        const SizedBox(width: 8),
        Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Text(period, style: const TextStyle(color: _Clr.muted, fontSize: 14))),
      ]),
      const SizedBox(height: 6),
      Container(height: 2, width: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [VetoPalette.primary, Colors.transparent]),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ]);
  }

  List<Widget> _featureLines() {
    final colors = [VetoPalette.success, VetoPalette.info, VetoPalette.warning];
    return [
      for (var i = 0; i < lines.length; i++) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Icon(Icons.check_rounded, color: colors[i], size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(lines[i], style: const TextStyle(color: _Clr.muted, fontSize: 14))),
          ]),
        ),
      ],
    ];
  }

  Widget _ctaButton() => _PrimaryBtn(label: buttonLabel, onTap: onTap);
}

// ═══════════════════════════════════════════════════════════════════
//  BOTTOM CTA SECTION — full-width dramatic
// ═══════════════════════════════════════════════════════════════════
class _CtaSection extends StatelessWidget {
  final String badge, title, body, buttonLabel;
  final bool compact;
  final VoidCallback onTap;
  const _CtaSection({
    required this.badge, required this.title, required this.body,
    required this.buttonLabel, required this.compact, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_Clr.heroBg, _Clr.heroBg2, _Clr.heroBg],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border(top: BorderSide(color: _Clr.heroBorder)),
      ),
      child: Stack(children: [
        // glow
        Positioned(
          top: -60, left: -60,
          child: Container(
            width: 360, height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_Clr.glow.withValues(alpha: 0.1), Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: compact ? 56 : 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: VetoPalette.primary.withValues(alpha: 0.08),
                    border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.35)),
                  ),
                  child: Text(badge.toUpperCase(), style: const TextStyle(
                    color: VetoPalette.info, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 2.5,
                  )),
                ),
                const SizedBox(height: 28),
                Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: VetoColors.white,
                    fontSize: compact ? 28 : 50,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _Clr.sub, fontSize: 16, height: 1.75),
                ),
                const SizedBox(height: 36),
                _PrimaryBtn(label: buttonLabel, onTap: onTap, large: true),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
//  INCIDENTS SECTION — 4 use-case cards (attorney-shield style)
// ═══════════════════════════════════════════════════════════════════
class _IncidentsSection extends StatelessWidget {
  final bool compact;
  final String code;
  const _IncidentsSection({required this.compact, required this.code});

  static const _data = {
    'he': {
      'eyebrow': 'כל מפגש עם רשויות האכיפה',
      'title': 'הגנה משפטית בכל תרחיש',
      'subtitle': 'VETO מכסה את כל סוגי המפגשים עם גורמי אכיפה — בכל זמן, בכל מקום.',
      'inc1Title': 'עצירת תנועה',
      'inc1Body': 'נורות כחולות מאחוריך? VETO מחבר אותך מיידית לייעוץ משפטי חי שיגן על זכויותיך.',
      'inc2Title': 'תאונת דרכים',
      'inc2Body': 'אחרי תאונה — תיעוד מיידי, ייעוץ ביטוחי ומשפטי, ושמירה על ראיות מהשטח.',
      'inc3Title': 'עימות שגרתי',
      'inc3Body': 'בסיטואציות של מתח ביתי או ציבורי — עורך הדין מכייל את השיחה ומונע הסלמה.',
      'inc4Title': 'עצירה בהליכה',
      'inc4Body': 'נעצרת ברחוב? VETO מאשר זכויות, מנחה מה לומר ומזניק ייצוג מיידי.',
    },
    'en': {
      'eyebrow': 'All Police-Initiated Contact',
      'title': 'Unlimited Access to Legal Protection',
      'subtitle': 'VETO delivers real-time legal guidance for every type of law-enforcement encounter.',
      'inc1Title': 'Traffic Stops',
      'inc1Body': 'Blue lights behind you? One tap connects you to a live attorney who guides the encounter and protects your rights.',
      'inc2Title': 'Auto Accidents',
      'inc2Body': 'After a crash — document instantly, get expert legal guidance and avoid costly mistakes.',
      'inc3Title': 'Domestic',
      'inc3Body': 'When emotions run high, an attorney provides immediate guidance to de-escalate and protect your rights.',
      'inc4Title': 'Pedestrian',
      'inc4Body': 'Stopped while walking? An attorney affirms your rights, advises on compliance, and de-escalates encounters.',
    },
    'ru': {
      'eyebrow': 'Все контакты с полицией',
      'title': 'Юридическая защита в любой ситуации',
      'subtitle': 'VETO обеспечивает правовую поддержку при любом контакте с правоохранительными органами.',
      'inc1Title': 'Остановка ТС',
      'inc1Body': 'Мигалки сзади? Одно нажатие — и адвокат на связи, защищает ваши права в реальном времени.',
      'inc2Title': 'Аварии',
      'inc2Body': 'После ДТП — немедленная фиксация, юридическая консультация и защита от ошибок.',
      'inc3Title': 'Бытовые ситуации',
      'inc3Body': 'В напряжённых ситуациях адвокат помогает де-эскалировать и соблюдать ваши права.',
      'inc4Title': 'Пешеходные остановки',
      'inc4Body': 'Остановили на улице? Адвокат подтверждает ваши права и советует, как вести себя.',
    },
  };

  Map<String, String> get _t => _data[code] ?? _data['en']!;

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final incidents = [
      _ItemData(icon: Icons.directions_car_filled_outlined, accent: const Color(0xFF6366F1), title: t['inc1Title']!, body: t['inc1Body']!),
      _ItemData(icon: Icons.car_crash_outlined, accent: const Color(0xFFF97316), title: t['inc2Title']!, body: t['inc2Body']!),
      _ItemData(icon: Icons.home_outlined, accent: const Color(0xFF2ECC71), title: t['inc3Title']!, body: t['inc3Body']!),
      _ItemData(icon: Icons.directions_walk_rounded, accent: const Color(0xFFEF4444), title: t['inc4Title']!, body: t['inc4Body']!),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 28, height: 1.5, color: VetoPalette.primary),
              const SizedBox(width: 10),
              Text(t['eyebrow']!.toUpperCase(), style: const TextStyle(
                color: VetoPalette.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3,
              )),
            ]),
            const SizedBox(height: 14),
            Text(t['title']!, style: const TextStyle(
              color: Color(0xFF07101C), fontSize: 36, fontWeight: FontWeight.w900, height: 1.1,
            )),
            const SizedBox(height: 12),
            Text(t['subtitle']!, style: const TextStyle(color: _Clr.muted, fontSize: 15, height: 1.8)),
            const SizedBox(height: 36),
            compact
                ? Column(children: [
                    for (var i = 0; i < incidents.length; i++) ...[
                      _IncidentCard(data: incidents[i]),
                      if (i < incidents.length - 1) const SizedBox(height: 10),
                    ],
                  ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var i = 0; i < incidents.length; i++) ...[
                      Expanded(child: _IncidentCard(data: incidents[i])),
                      if (i < incidents.length - 1) const SizedBox(width: 10),
                    ],
                  ]),
          ]),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final _ItemData data;
  const _IncidentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Clr.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Clr.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07101C).withValues(alpha: 0.12),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(data.icon, size: 28, color: data.accent),
        const SizedBox(height: 14),
        Text(data.title, style: TextStyle(
          color: data.accent, fontSize: 15, fontWeight: FontWeight.w800,
        )),
        const SizedBox(height: 8),
        Text(data.body, style: const TextStyle(color: _Clr.muted, fontSize: 13, height: 1.7)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TESTIMONIALS SECTION — social proof cards
// ═══════════════════════════════════════════════════════════════════
class _TestimonialsSection extends StatelessWidget {
  final bool compact;
  final String code;
  const _TestimonialsSection({required this.compact, required this.code});

  static const _sectionLabel = {
    'he': 'מה אומרים המשתמשים',
    'en': 'Trusted by Users Nationwide',
    'ru': 'Отзывы наших пользователей',
  };
  static const _subtitle = {
    'he': 'חוויות אמיתיות של אנשים שהשתמשו ב-VETO ברגע הקריטי.',
    'en': 'Real experiences from people who used VETO when it mattered most.',
    'ru': 'Реальные истории людей, которые воспользовались VETO в нужный момент.',
  };

  static const _reviews = [
    (name: 'David B.',   date: '04/2025', text: 'Having an attorney with me in real time when I needed one was an absolute game changer. The confidence and security I felt was enough to keep the situation in check.', rating: 5),
    (name: 'Adam H.',    date: '07/2025', text: 'I used this app at a traffic stop. It works great! The licensed attorney was on the phone within seconds. Amazing!', rating: 5),
    (name: 'Mike K.',    date: '09/2025', text: 'The attorney provided excellent support when I was questioned by police while parked on a public road. Highly recommend.', rating: 5),
  ];

  @override
  Widget build(BuildContext context) {
    final label   = _sectionLabel[code] ?? _sectionLabel['en']!;
    final subtitle = _subtitle[code]    ?? _subtitle['en']!;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 28, height: 1.5, color: VetoPalette.primary),
              const SizedBox(width: 10),
              Text(label.toUpperCase(), style: const TextStyle(
                color: VetoPalette.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3,
              )),
            ]),
            const SizedBox(height: 14),
            Text(subtitle, style: const TextStyle(color: _Clr.muted, fontSize: 14, height: 1.6)),
            const SizedBox(height: 32),
            compact
                ? Column(children: [
                    for (var i = 0; i < _reviews.length; i++) ...[
                      _ReviewCard(review: _reviews[i]),
                      if (i < _reviews.length - 1) const SizedBox(height: 10),
                    ],
                  ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var i = 0; i < _reviews.length; i++) ...[
                      Expanded(child: _ReviewCard(review: _reviews[i])),
                      if (i < _reviews.length - 1) const SizedBox(width: 10),
                    ],
                  ]),
          ]),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ({String name, String date, String text, int rating}) review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _Clr.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Clr.border),
        boxShadow: [
          BoxShadow(color: const Color(0xFF07101C).withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (int i = 0; i < review.rating; i++)
            const Icon(Icons.star_rounded, color: Color(0xFF0D9488), size: 14),
          const Spacer(),
          Text(review.date, style: const TextStyle(color: _Clr.sub, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Text('"${review.text}"', style: const TextStyle(color: _Clr.muted, fontSize: 13, height: 1.65, fontStyle: FontStyle.italic)),
        const SizedBox(height: 14),
        Text(review.name, style: const TextStyle(color: _Clr.sub, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {  final String label;
  final VoidCallback onTap;
  final bool large;
  const _PrimaryBtn({required this.label, required this.onTap, this.large = false});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.bolt_rounded, size: large ? 18 : 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: VetoPalette.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 28 : 20,
          vertical: large ? 18 : 13,
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: large ? 15 : 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}

class _ProofChip extends StatelessWidget {
  final String label;
  const _ProofChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: _Clr.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _Clr.heroBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_outline_rounded, color: VetoPalette.info, size: 13),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          color: _Clr.sub,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        )),
      ]),
    );
  }
}
