import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_language_menu.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Map<String, Map<String, String>> _copy = {
    'he': {
      'navLogin': 'כניסה',
      'navCta': 'פתיחת חשבון',
      'heroBadge': 'תגובה משפטית חכמה, אנושית ורב-לשונית',
      'heroTitle': 'במצב לחץ לא מחפשים עזרה.\nפותחים את VETO.',
      'heroBody': 'מערכת אחת שמחברת עוזר AI, תרחישי זכויות, תיעוד ראיות ושיגור עורך דין לזמן אמת.',
      'heroPrimary': 'התחל באשף',
      'heroSecondary': 'כניסה מהירה',
      'proof1': 'AI משפטי בכל רגע',
      'proof2': 'עברית, English, Русский',
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
      'flow1Title': '1. בחירת תפקיד ושפה',
      'flow1Body': 'האשף מגדיר אם אתה אזרח, עורך דין או מנהל, ושומר את שפת העבודה שלך להמשך.',
      'flow2Title': '2. אימות מהיר וכניסה למסך הנכון',
      'flow2Body': 'אחרי OTP, כל תפקיד מגיע ישירות למסך הייעודי שלו בלי ניווט צדדי מבלבל.',
      'flow3Title': '3. עבודה שוטפת או חירום מיידי',
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
      'ctaTitle': 'בונים שכבת הגנה לפני שהאירוע מתחיל',
      'ctaBody': 'ההרשמה קצרה. מהרגע שהיא מסתיימת, כל חירום משפטי מקבל מסך ברור ומוכן לפעולה.',
      'ctaButton': 'לעבור לאשף',
      'footer': 'VETO | מערכת תגובה משפטית חכמה, מהירה ורב-לשונית',
    },
    'en': {
      'navLogin': 'Sign in',
      'navCta': 'Create account',
      'heroBadge': 'Smart, human, multilingual legal response',
      'heroTitle': 'In a high-pressure moment, you do not search for help.\nYou open VETO.',
      'heroBody': 'One system that combines an AI legal assistant, rights scenarios, evidence capture, and real-time lawyer dispatch.',
      'heroPrimary': 'Start the wizard',
      'heroSecondary': 'Quick sign in',
      'proof1': 'Legal AI whenever you need it',
      'proof2': 'Hebrew, English, Russian',
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
      'flow1Title': '1. Choose role and language',
      'flow1Body': 'The wizard defines whether you are a citizen, lawyer, or admin, and stores your working language.',
      'flow2Title': '2. Verify quickly and land on the right console',
      'flow2Body': 'After OTP, each role goes straight to its dedicated screen without confusing side navigation.',
      'flow3Title': '3. Work normally or escalate instantly',
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
      'ctaTitle': 'Build your legal safety layer before the incident begins',
      'ctaBody': 'Registration is short. Once it is done, every legal emergency starts from one clear, ready-to-use interface.',
      'ctaButton': 'Open the wizard',
      'footer': 'VETO | Fast, intelligent, multilingual legal response',
    },
    'ru': {
      'navLogin': 'Вход',
      'navCta': 'Создать аккаунт',
      'heroBadge': 'Умная, человеческая и мультиязычная юридическая реакция',
      'heroTitle': 'В момент давления не ищут помощь.\nОткрывают VETO.',
      'heroBody': 'Единая система, которая соединяет юридический AI, сценарии прав, фиксацию доказательств и вызов адвоката в реальном времени.',
      'heroPrimary': 'Открыть мастер',
      'heroSecondary': 'Быстрый вход',
      'proof1': 'Юридический AI в любой момент',
      'proof2': 'Иврит, английский, русский',
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
      'flow1Title': '1. Выбор роли и языка',
      'flow1Body': 'Мастер определяет, кто вы: гражданин, адвокат или администратор, и сохраняет рабочий язык.',
      'flow2Title': '2. Быстрая проверка и вход в нужную панель',
      'flow2Body': 'После OTP каждая роль попадает прямо на свой экран без лишней навигации.',
      'flow3Title': '3. Обычная работа или мгновенная эскалация',
      'flow3Body': 'Можно продолжить с AI, выбрать сценарий, зафиксировать доказательства или запустить SOS для живой юридической реакции.',
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
      'ctaTitle': 'Создайте юридический слой защиты до начала инцидента',
      'ctaBody': 'Регистрация занимает минимум времени. После нее любое юридическое ЧП начинается с одного понятного рабочего экрана.',
      'ctaButton': 'Перейти к мастеру',
      'footer': 'VETO | Быстрая, умная и мультиязычная юридическая реакция',
    },
  };

  String _t(String code, String key) {
    return _copy[AppLanguage.normalize(code)]?[key] ??
        _copy[AppLanguage.hebrew]![key] ??
        key;
  }

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
    final direction = AppLanguage.directionOf(code);
    final compact = MediaQuery.of(context).size.width < 960;

    final signals = <_PanelData>[
      _PanelData(
        icon: Icons.rule_folder_outlined,
        color: VetoPalette.primary,
        title: _t(code, 'signal1Title'),
        body: _t(code, 'signal1Body'),
      ),
      _PanelData(
        icon: Icons.smart_toy_outlined,
        color: VetoPalette.info,
        title: _t(code, 'signal2Title'),
        body: _t(code, 'signal2Body'),
      ),
      _PanelData(
        icon: Icons.perm_media_outlined,
        color: VetoPalette.warning,
        title: _t(code, 'signal3Title'),
        body: _t(code, 'signal3Body'),
      ),
    ];

    final flow = <_PanelData>[
      _PanelData(
        index: '01',
        icon: Icons.language_rounded,
        color: VetoPalette.primary,
        title: _t(code, 'flow1Title'),
        body: _t(code, 'flow1Body'),
      ),
      _PanelData(
        index: '02',
        icon: Icons.verified_user_outlined,
        color: VetoPalette.success,
        title: _t(code, 'flow2Title'),
        body: _t(code, 'flow2Body'),
      ),
      _PanelData(
        index: '03',
        icon: Icons.crisis_alert_rounded,
        color: VetoPalette.emergency,
        title: _t(code, 'flow3Title'),
        body: _t(code, 'flow3Body'),
      ),
    ];

    final audiences = <_PanelData>[
      _PanelData(
        icon: Icons.person_search_outlined,
        color: VetoPalette.primary,
        title: _t(code, 'audience1Title'),
        body: _t(code, 'audience1Body'),
      ),
      _PanelData(
        icon: Icons.gavel_rounded,
        color: VetoPalette.success,
        title: _t(code, 'audience2Title'),
        body: _t(code, 'audience2Body'),
      ),
      _PanelData(
        icon: Icons.admin_panel_settings_outlined,
        color: VetoPalette.warning,
        title: _t(code, 'audience3Title'),
        body: _t(code, 'audience3Body'),
      ),
    ];

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
          child: Column(
            children: [
              _LandingNav(
                loginLabel: _t(code, 'navLogin'),
                ctaLabel: _t(code, 'navCta'),
                onTap: () => _goNext(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: compact
                      ? Column(
                          children: [
                            _LandingHero(
                              badge: _t(code, 'heroBadge'),
                              title: _t(code, 'heroTitle'),
                              body: _t(code, 'heroBody'),
                              primaryLabel: _t(code, 'heroPrimary'),
                              secondaryLabel: _t(code, 'heroSecondary'),
                              proof1: _t(code, 'proof1'),
                              proof2: _t(code, 'proof2'),
                              proof3: _t(code, 'proof3'),
                              onTap: () => _goNext(context),
                            ),
                            const SizedBox(height: 16),
                            _ResponseRail(
                              title: _t(code, 'stackTitle'),
                              items: [
                                _PanelData(
                                  icon: Icons.explore_outlined,
                                  color: VetoPalette.primary,
                                  title: _t(code, 'stack1Title'),
                                  body: _t(code, 'stack1Body'),
                                ),
                                _PanelData(
                                  icon: Icons.auto_awesome_outlined,
                                  color: VetoPalette.info,
                                  title: _t(code, 'stack2Title'),
                                  body: _t(code, 'stack2Body'),
                                ),
                                _PanelData(
                                  icon: Icons.notifications_active_outlined,
                                  color: VetoPalette.success,
                                  title: _t(code, 'stack3Title'),
                                  body: _t(code, 'stack3Body'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: _LandingHero(
                                badge: _t(code, 'heroBadge'),
                                title: _t(code, 'heroTitle'),
                                body: _t(code, 'heroBody'),
                                primaryLabel: _t(code, 'heroPrimary'),
                                secondaryLabel: _t(code, 'heroSecondary'),
                                proof1: _t(code, 'proof1'),
                                proof2: _t(code, 'proof2'),
                                proof3: _t(code, 'proof3'),
                                onTap: () => _goNext(context),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 9,
                              child: _ResponseRail(
                                title: _t(code, 'stackTitle'),
                                items: [
                                  _PanelData(
                                    icon: Icons.explore_outlined,
                                    color: VetoPalette.primary,
                                    title: _t(code, 'stack1Title'),
                                    body: _t(code, 'stack1Body'),
                                  ),
                                  _PanelData(
                                    icon: Icons.auto_awesome_outlined,
                                    color: VetoPalette.info,
                                    title: _t(code, 'stack2Title'),
                                    body: _t(code, 'stack2Body'),
                                  ),
                                  _PanelData(
                                    icon: Icons.notifications_active_outlined,
                                    color: VetoPalette.success,
                                    title: _t(code, 'stack3Title'),
                                    body: _t(code, 'stack3Body'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              _LandingSection(
                eyebrow: _t(code, 'sectionSignals'),
                title: _t(code, 'signalsTitle'),
                child: _LandingGrid(items: signals),
              ),
              _LandingSection(
                eyebrow: _t(code, 'sectionFlow'),
                title: _t(code, 'flowTitle'),
                child: _LandingGrid(items: flow),
              ),
              _LandingSection(
                eyebrow: _t(code, 'sectionAudience'),
                title: _t(code, 'audienceTitle'),
                child: _LandingGrid(items: audiences),
              ),
              _LandingSection(
                eyebrow: _t(code, 'sectionPricing'),
                title: _t(code, 'pricingTitle'),
                subtitle: _t(code, 'pricingBody'),
                child: _PricingPanel(
                  planName: _t(code, 'planName'),
                  price: _t(code, 'planPrice'),
                  period: _t(code, 'planPeriod'),
                  line1: _t(code, 'planLine1'),
                  line2: _t(code, 'planLine2'),
                  line3: _t(code, 'planLine3'),
                  buttonLabel: _t(code, 'heroPrimary'),
                  onTap: () => _goNext(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: _BottomCallout(
                    title: _t(code, 'ctaTitle'),
                    body: _t(code, 'ctaBody'),
                    buttonLabel: _t(code, 'ctaButton'),
                    onTap: () => _goNext(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Text(
                  _t(code, 'footer'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VetoPalette.textSubtle,
                    fontSize: 12,
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

class _LandingNav extends StatelessWidget {
  final String loginLabel;
  final String ctaLabel;
  final VoidCallback onTap;

  const _LandingNav({
    required this.loginLabel,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: VetoPalette.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: VetoPalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: VetoPalette.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: VetoPalette.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'VETO',
                style: TextStyle(
                  color: VetoPalette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              const AppLanguageMenu(compact: true),
              const SizedBox(width: 8),
              TextButton(onPressed: onTap, child: Text(loginLabel)),
              const SizedBox(width: 6),
              FilledButton(onPressed: onTap, child: Text(ctaLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingHero extends StatelessWidget {
  final String badge;
  final String title;
  final String body;
  final String primaryLabel;
  final String secondaryLabel;
  final String proof1;
  final String proof2;
  final String proof3;
  final VoidCallback onTap;

  const _LandingHero({
    required this.badge,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.proof1,
    required this.proof2,
    required this.proof3,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 720;
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF122744), Color(0xFF0F1D33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VetoPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: VetoPalette.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: VetoPalette.info,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: VetoPalette.text,
              fontSize: compact ? 34 : 52,
              fontWeight: FontWeight.w900,
              height: 1.06,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: const TextStyle(
              color: VetoPalette.textMuted,
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(primaryLabel),
              ),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(secondaryLabel),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProofPill(label: proof1),
              _ProofPill(label: proof2),
              _ProofPill(label: proof3),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProofPill extends StatelessWidget {
  final String label;

  const _ProofPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: VetoPalette.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ResponseRail extends StatelessWidget {
  final String title;
  final List<_PanelData> items;

  const _ResponseRail({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: VetoPalette.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < items.length; index++) ...[
            _InfoPanel(data: items[index]),
            if (index < items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LandingSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget child;

  const _LandingSection({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: VetoPalette.info,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: VetoPalette.text,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: VetoPalette.textMuted,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _LandingGrid extends StatelessWidget {
  final List<_PanelData> items;

  const _LandingGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 960;
    if (compact) {
      return Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _InfoPanel(data: items[index]),
            if (index < items.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: _InfoPanel(data: items[index])),
          if (index < items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final _PanelData data;

  const _InfoPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VetoPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.index != null)
            Text(
              data.index!,
              style: TextStyle(
                color: data.color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(
              color: VetoPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.body,
            style: const TextStyle(
              color: VetoPalette.textMuted,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingPanel extends StatelessWidget {
  final String planName;
  final String price;
  final String period;
  final String line1;
  final String line2;
  final String line3;
  final String buttonLabel;
  final VoidCallback onTap;

  const _PricingPanel({
    required this.planName,
    required this.price,
    required this.period,
    required this.line1,
    required this.line2,
    required this.line3,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            planName,
            style: const TextStyle(
              color: VetoPalette.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: VetoPalette.primary,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  period,
                  style: const TextStyle(
                    color: VetoPalette.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PlanLine(text: line1),
          _PlanLine(text: line2),
          _PlanLine(text: line3),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  final String text;

  const _PlanLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: VetoPalette.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: VetoPalette.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCallout extends StatelessWidget {
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onTap;

  const _BottomCallout({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            VetoPalette.primary.withValues(alpha: 0.18),
            VetoPalette.info.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.26)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VetoPalette.text,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VetoPalette.textMuted,
              fontSize: 15,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.rocket_launch_outlined, size: 18),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _PanelData {
  final String? index;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _PanelData({
    this.index,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}