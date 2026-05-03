// ============================================================
//  OnboardingWizardScreen — 1:1 port of 2026/wizard.html
//  4-step onboarding quiz: role → scenario → alerts → privacy.
//  Runs at `/wizard_home` for first-time citizens after verify-OTP.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_2026.dart';
import '../../core/theme/veto_2026_wizard.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_language_menu.dart';

/// Single option definition (role / scenario / alerts / privacy).
class _Opt {
  final String id;
  final IconData icon;
  final Map<String, String> title;
  final Map<String, String> desc;
  const _Opt(this.id, this.icon, this.title, this.desc);
  String t(String code) => title[code] ?? title['he'] ?? id;
  String d(String code) => desc[code] ?? desc['he'] ?? '';
}

/// Step 1 — role. Always defaulted to citizen on this path; we still
/// surface the question because the mockup shows it explicitly.
const List<_Opt> _roleOpts = [
  _Opt(
    'citizen',
    Icons.shield_rounded,
    {'he': 'אזרח', 'en': 'Citizen', 'ru': 'Гражданин'},
    {
      'he': 'גישה להגנה משפטית מיידית וכפתור SOS',
      'en': 'Instant legal defense and SOS button',
      'ru': 'Мгновенная защита и кнопка SOS',
    },
  ),
  _Opt(
    'lawyer',
    Icons.gavel_rounded,
    {'he': 'עו״ד', 'en': 'Lawyer', 'ru': 'Адвокат'},
    {
      'he': 'קבלת תיקים מ-VETO בזמן אמת',
      'en': 'Receive cases from VETO in real time',
      'ru': 'Принимать дела от VETO в реальном времени',
    },
  ),
];

const List<_Opt> _scenarioOpts = [
  _Opt(
    'police',
    Icons.shield_rounded,
    {
      'he': 'חקירה במשטרה',
      'en': 'Police investigation',
      'ru': 'Допрос в полиции',
    },
    {
      'he': 'זימון, חקירה תחת אזהרה, מעצר ראשוני',
      'en': 'Summons, caution, initial arrest',
      'ru': 'Повестка, допрос под предупреждением, задержание',
    },
  ),
  _Opt(
    'traffic',
    Icons.traffic_rounded,
    {
      'he': 'עצירת תנועה',
      'en': 'Traffic stop',
      'ru': 'Остановка ГИБДД',
    },
    {
      'he': 'בקרת מהירות, אלכוהול, רישיון',
      'en': 'Speed, alcohol, license check',
      'ru': 'Скорость, алкоголь, права',
    },
  ),
  _Opt(
    'civil',
    Icons.description_rounded,
    {
      'he': 'סכסוך אזרחי',
      'en': 'Civil dispute',
      'ru': 'Гражданский спор',
    },
    {
      'he': 'חוזה, נדל"ן, נזיקין',
      'en': 'Contract, real estate, tort',
      'ru': 'Договор, недвижимость, ущерб',
    },
  ),
  _Opt(
    'labor',
    Icons.work_rounded,
    {
      'he': 'דיני עבודה',
      'en': 'Labor law',
      'ru': 'Трудовое право',
    },
    {
      'he': 'פיטורין, זכויות, הטרדה',
      'en': 'Dismissal, rights, harassment',
      'ru': 'Увольнение, права, домогательства',
    },
  ),
  _Opt(
    'family',
    Icons.family_restroom_rounded,
    {
      'he': 'דיני משפחה',
      'en': 'Family law',
      'ru': 'Семейное право',
    },
    {
      'he': 'גירושין, ילדים, מזונות',
      'en': 'Divorce, custody, alimony',
      'ru': 'Развод, дети, алименты',
    },
  ),
  _Opt(
    'consumer',
    Icons.shopping_bag_rounded,
    {
      'he': 'צרכנות',
      'en': 'Consumer',
      'ru': 'Потребители',
    },
    {
      'he': 'החזר, אחריות, הונאה',
      'en': 'Refund, warranty, fraud',
      'ru': 'Возврат, гарантия, мошенничество',
    },
  ),
];

const List<_Opt> _alertsOpts = [
  _Opt(
    'push_sms',
    Icons.notifications_active_rounded,
    {
      'he': 'Push + SMS',
      'en': 'Push + SMS',
      'ru': 'Push + SMS',
    },
    {
      'he': 'לא תפספס קריאה — שילוב של שני הערוצים',
      'en': "Won't miss a call — both channels combined",
      'ru': 'Не пропустите вызов — оба канала',
    },
  ),
  _Opt(
    'push',
    Icons.phone_android_rounded,
    {
      'he': 'Push בלבד',
      'en': 'Push only',
      'ru': 'Только Push',
    },
    {
      'he': 'בהתראה אחת על המכשיר',
      'en': 'Single device notification',
      'ru': 'Одно уведомление на устройстве',
    },
  ),
  _Opt(
    'sms',
    Icons.sms_rounded,
    {
      'he': 'SMS בלבד',
      'en': 'SMS only',
      'ru': 'Только SMS',
    },
    {
      'he': 'ללא תלות באפליקציה',
      'en': 'App-independent',
      'ru': 'Без приложения',
    },
  ),
  _Opt(
    'call',
    Icons.call_rounded,
    {
      'he': 'שיחה אוטומטית',
      'en': 'Auto call',
      'ru': 'Автозвонок',
    },
    {
      'he': 'לכוח עליון — שיחה מיידית',
      'en': 'Emergency only — instant call',
      'ru': 'Только экстренно — мгновенный вызов',
    },
  ),
];

const List<_Opt> _privacyOpts = [
  _Opt(
    'anonymous',
    Icons.visibility_off_rounded,
    {
      'he': 'אנונימי לעו״ד',
      'en': 'Anonymous to lawyer',
      'ru': 'Анонимно для адвоката',
    },
    {
      'he': 'שם נחשף רק אם תאשר',
      'en': 'Name revealed only on your approval',
      'ru': 'Имя — только с вашего согласия',
    },
  ),
  _Opt(
    'verified',
    Icons.verified_user_rounded,
    {
      'he': 'מזוהה',
      'en': 'Verified',
      'ru': 'Идентифицирован',
    },
    {
      'he': 'שמך יוצג לעו״ד מהרגע הראשון',
      'en': 'Name shown to lawyer from the start',
      'ru': 'Имя показано адвокату с самого начала',
    },
  ),
];

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _step = 1; // 1..4 (matches mockup wording "שאלה N מתוך 4")
  String _role = 'citizen';
  String _scenario = 'police';
  String _alerts = 'push_sms';
  String _privacy = 'anonymous';

  DateTime _lastSaved = DateTime.now();
  Timer? _saveTicker;
  bool _submitting = false;

  static const int _stepCount = 4;

  @override
  void initState() {
    super.initState();
    _saveTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // refresh "נשמר אוטומטית · לפני N שניות"
    });
  }

  @override
  void dispose() {
    _saveTicker?.cancel();
    super.dispose();
  }

  void _touchSaved() => _lastSaved = DateTime.now();

  String _saveStatusText(String code) {
    final secs = DateTime.now().difference(_lastSaved).inSeconds;
    final n = secs.clamp(0, 999);
    if (code == 'he') return 'נשמר אוטומטית · לפני ${n == 0 ? 'רגע' : '$n שניות'}';
    if (code == 'ru') {
      return n == 0
          ? 'Сохранено автоматически · только что'
          : 'Сохранено автоматически · $n сек назад';
    }
    return n == 0
        ? 'Auto-saved · just now'
        : 'Auto-saved · ${n}s ago';
  }

  String _stepTitle(int idx, String code) {
    const titles = {
      1: {'he': 'תפקיד', 'en': 'Role', 'ru': 'Роль'},
      2: {'he': 'תרחיש מרכזי', 'en': 'Main scenario', 'ru': 'Сценарий'},
      3: {'he': 'העדפות התראות', 'en': 'Alert preferences', 'ru': 'Уведомления'},
      4: {'he': 'פרטיות', 'en': 'Privacy', 'ru': 'Приватность'},
    };
    return titles[idx]?[code] ?? titles[idx]?['he'] ?? '';
  }

  String _stepSubtitle(int idx, String code) {
    const subtitles = {
      1: {
        'he': 'האם אתה אזרח או עו״ד?',
        'en': 'Citizen or lawyer?',
        'ru': 'Гражданин или адвокат?',
      },
      2: {
        'he': 'איזה סוג חירום הכי רלוונטי לך?',
        'en': 'Which emergency type is most relevant?',
        'ru': 'Какой сценарий самый важный?',
      },
      3: {
        'he': 'איך נדע לאתר אותך מהר?',
        'en': 'How should we reach you fast?',
        'ru': 'Как быстрее с вами связаться?',
      },
      4: {
        'he': 'מי רואה את הנתונים שלך',
        'en': 'Who sees your data',
        'ru': 'Кто видит ваши данные',
      },
    };
    return subtitles[idx]?[code] ?? subtitles[idx]?['he'] ?? '';
  }

  List<_Opt> _optsFor(int step) {
    switch (step) {
      case 1:
        return _roleOpts;
      case 2:
        return _scenarioOpts;
      case 3:
        return _alertsOpts;
      case 4:
        return _privacyOpts;
    }
    return const [];
  }

  String _currentSelection() {
    switch (_step) {
      case 1:
        return _role;
      case 2:
        return _scenario;
      case 3:
        return _alerts;
      case 4:
        return _privacy;
    }
    return '';
  }

  void _select(String id) {
    setState(() {
      switch (_step) {
        case 1:
          _role = id;
          break;
        case 2:
          _scenario = id;
          break;
        case 3:
          _alerts = id;
          break;
        case 4:
          _privacy = id;
          break;
      }
      _touchSaved();
    });
  }

  Future<void> _next() async {
    if (_step < _stepCount) {
      setState(() {
        _step += 1;
        _touchSaved();
      });
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step <= 1) return;
    setState(() {
      _step -= 1;
      _touchSaved();
    });
  }

  Future<void> _saveExit() async {
    final auth = AuthService();
    await auth.saveOnboarding(
      scenario: _scenario,
      alerts: _alerts,
      privacy: _privacy,
    );
    if (!mounted) return;
    _routeForRole();
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final auth = AuthService();
    await auth.saveOnboarding(
      scenario: _scenario,
      alerts: _alerts,
      privacy: _privacy,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    _routeForRole();
  }

  void _routeForRole() {
    final target = _role == 'lawyer' ? '/lawyer_dashboard' : '/veto_screen';
    Navigator.of(context).pushReplacementNamed(target);
  }

  // ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= V26AppShell.desktopBreakpoint;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: V26.paper,
        body: SafeArea(
          child: isWide ? _buildDesktop(code) : _buildMobile(code),
        ),
      ),
    );
  }

  Widget _buildDesktop(String code) {
    return Row(
      children: [
        V26WizardRail(
          brandEm: code == 'he'
              ? 'Wizard'
              : (code == 'ru' ? 'Мастер' : 'Wizard'),
          headlineLine1: code == 'he'
              ? 'בוא נכין'
              : (code == 'ru' ? 'Настроим' : 'Let\'s prepare'),
          headlineBeforeEm: code == 'he'
              ? 'את '
              : (code == 'ru' ? '' : ''),
          headlineEm: 'VETO',
          headlineLine3: code == 'he'
              ? 'בדיוק לך'
              : (code == 'ru' ? 'именно под вас' : 'just for you'),
          description: code == 'he'
              ? '4 שאלות קצרות שיעזרו לנו להתאים את המסך, את ההתראות ואת זמן התגובה — בהתאם למה שאתה צריך.'
              : (code == 'ru'
                  ? '4 коротких вопроса помогут нам настроить экран, уведомления и время реакции — под ваши нужды.'
                  : '4 short questions help us tailor the screen, alerts and response time — to what you need.'),
          stepTitles: [
            _stepTitle(1, code),
            _stepTitle(2, code),
            _stepTitle(3, code),
            _stepTitle(4, code),
          ],
          stepSubtitles: [
            _stepSubtitleShort(1, code, _role),
            _stepSubtitleShort(2, code, _scenario),
            _stepSubtitleShort(3, code, _alerts),
            _stepSubtitleShort(4, code, _privacy),
          ],
          currentStepIndex: _step - 1,
          saveStatusLine: _saveStatusText(code),
          saveExitLabel: code == 'he'
              ? 'שמור וצא'
              : (code == 'ru' ? 'Сохранить и выйти' : 'Save & exit'),
          onSaveExit: _saveExit,
        ),
        Expanded(
          child: Column(
            children: [
              _wizTopbar(code, compact: false),
              Expanded(child: _wizBody(code, compact: false)),
              V26WizFoot(
                backLabel: _step > 1
                    ? (code == 'he'
                        ? '← חזרה'
                        : (code == 'ru' ? '← Назад' : '← Back'))
                    : null,
                onBack: _back,
                nextLabel: _step < _stepCount
                    ? (code == 'he'
                        ? 'המשך →'
                        : (code == 'ru' ? 'Продолжить →' : 'Continue →'))
                    : (code == 'he'
                        ? 'סיים והתחל →'
                        : (code == 'ru' ? 'Завершить →' : 'Finish →')),
                onNext: _submitting ? null : _next,
                hint: _step < _stepCount ? _nextHint(code) : null,
                compact: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _stepSubtitleShort(int idx, String code, String selectedId) {
    if (idx > _step) return _stepSubtitle(idx, code);
    final selected = _optsFor(idx).firstWhere(
      (o) => o.id == selectedId,
      orElse: () => _optsFor(idx).first,
    );
    if (idx < _step) {
      final label = code == 'he'
          ? 'נבחר'
          : (code == 'ru' ? 'выбрано' : 'selected');
      return '${selected.t(code)} · $label';
    }
    return _stepSubtitle(idx, code);
  }

  Widget _buildMobile(String code) {
    return Column(
      children: [
        _wizTopbar(code, compact: true),
        V26WizardPhoneProgress(
          stepIndexZeroBased: _step - 1,
          stepCount: _stepCount,
          labelBold: code == 'he'
              ? 'שאלה $_step מתוך $_stepCount'
              : (code == 'ru'
                  ? 'Вопрос $_step из $_stepCount'
                  : 'Question $_step of $_stepCount'),
          labelDetail: _stepTitle(_step, code),
        ),
        Expanded(child: _wizBody(code, compact: true)),
        V26WizFoot(
          backLabel: _step > 1
              ? (code == 'he' ? '←' : (code == 'ru' ? '←' : '←'))
              : null,
          onBack: _back,
          nextLabel: _step < _stepCount
              ? (code == 'he'
                  ? 'המשך'
                  : (code == 'ru' ? 'Продолжить' : 'Continue'))
              : (code == 'he'
                  ? 'סיים והתחל →'
                  : (code == 'ru' ? 'Завершить →' : 'Finish →')),
          onNext: _submitting ? null : _next,
          compact: true,
        ),
      ],
    );
  }

  String _nextHint(String code) {
    final nextIdx = _step + 1;
    if (nextIdx > _stepCount) return '';
    final prefix = code == 'he'
        ? 'השאלה הבאה: '
        : (code == 'ru' ? 'Следующий вопрос: ' : 'Next: ');
    return '$prefix${_stepTitle(nextIdx, code)}';
  }

  Widget _wizTopbar(String code, {required bool compact}) {
    final stepLabel = code == 'he'
        ? 'שאלה $_step מתוך $_stepCount'
        : (code == 'ru'
            ? 'Вопрос $_step из $_stepCount'
            : 'Question $_step of $_stepCount');
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(14, 14, 14, 12)
          : const EdgeInsets.fromLTRB(32, 18, 32, 18),
      decoration: const BoxDecoration(
        color: V26.surface,
        border: Border(bottom: BorderSide(color: V26.hairline)),
      ),
      child: Row(
        children: [
          if (compact)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right,
                  color: V26.ink700, size: 22),
              onPressed: _step > 1 ? _back : null,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stepLabel,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: V26.ink500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepTitle(_step, code),
                  style: TextStyle(
                    fontFamily: V26.serif,
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: V26.ink900,
                  ),
                ),
              ],
            ),
          ),
          const AppLanguageMenu(compact: true),
          if (compact) ...[
            const SizedBox(width: 6),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded,
                  color: V26.ink700, size: 22),
              onPressed: _saveExit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _wizBody(String code, {required bool compact}) {
    if (_step == _stepCount) {
      return _summaryBody(code, compact: compact);
    }
    final opts = _optsFor(_step);
    final selected = _currentSelection();
    return SingleChildScrollView(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 18, 16, 18)
          : const EdgeInsets.fromLTRB(56, 32, 56, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: V26QuizCard(
            title: _buildQuestionHeadline(code),
            lede: _buildQuestionLede(code),
            compact: compact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                V26OptGrid(
                  compact: compact,
                  options: [
                    for (final o in opts)
                      V26OptTile(
                        icon: o.icon,
                        title: o.t(code),
                        description: o.d(code),
                        selected: selected == o.id,
                        onTap: () => _select(o.id),
                      ),
                  ],
                ),
                if (_step == 2) ...[
                  const SizedBox(height: 24),
                  _calloutInfo(code),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildQuestionHeadline(String code) {
    switch (_step) {
      case 1:
        return code == 'he'
            ? 'איך תשתמש ב-VETO?'
            : (code == 'ru'
                ? 'Как вы будете использовать VETO?'
                : 'How will you use VETO?');
      case 2:
        return code == 'he'
            ? 'איזה תרחיש הכי רלוונטי לך?'
            : (code == 'ru'
                ? 'Какой сценарий самый важный?'
                : 'Which scenario is most relevant?');
      case 3:
        return code == 'he'
            ? 'איך נדע לאתר אותך מהר?'
            : (code == 'ru'
                ? 'Как с вами связаться быстрее?'
                : 'How should we reach you fast?');
      case 4:
        return code == 'he'
            ? 'מי רואה את הנתונים שלך?'
            : (code == 'ru'
                ? 'Кто видит ваши данные?'
                : 'Who sees your data?');
    }
    return '';
  }

  String _buildQuestionLede(String code) {
    switch (_step) {
      case 1:
        return code == 'he'
            ? 'נתאים את המסך ואת הפעולות בהתאם לתפקיד שלך. תוכל לשנות בכל זמן בהגדרות.'
            : (code == 'ru'
                ? 'Настроим интерфейс под вашу роль. Можно поменять в настройках.'
                : 'We tailor the UI to your role. You can change this later in settings.');
      case 2:
        return code == 'he'
            ? 'בחר את התרחיש שאתה הכי צופה שיקרה — נתאים לך מסך מותאם, זכויות מוקרנות מראש, ועו"ד מתחום ההתמחות הנכון. תוכל לשנות בכל זמן בהגדרות.'
            : (code == 'ru'
                ? 'Выберите самый ожидаемый сценарий — подстроим экран, права и специализацию адвоката. Можно изменить в любое время.'
                : 'Pick the scenario you expect most — we preload rights and route to the right lawyer. Change any time.');
      case 3:
        return code == 'he'
            ? 'בחר את האופן שבו נעדיף להתריע אם יש אירוע דחוף. תוכל לשנות בכל זמן.'
            : (code == 'ru'
                ? 'Как предпочтительно уведомлять о срочных событиях?'
                : 'Pick how we should notify you of urgent events.');
      case 4:
        return code == 'he'
            ? 'בחר את רמת הפרטיות שתרצה שלעו״ד הזמין יהיה אליך. תוכל לשנות בכל זמן.'
            : (code == 'ru'
                ? 'Выберите уровень приватности для адвоката.'
                : 'Choose the privacy level you want toward the on-duty lawyer.');
    }
    return '';
  }

  Widget _calloutInfo(String code) {
    final body = code == 'he'
        ? 'הבחירה משפיעה על המסך הראשי בלבד. כל שאר התרחישים יישארו זמינים בכל רגע — כפתור SOS לא מבחין בין סוגים.'
        : (code == 'ru'
            ? 'Выбор влияет только на главный экран. Все сценарии остаются доступны в любой момент — кнопка SOS не делит их по типам.'
            : 'This affects only the main screen. All scenarios remain available — the SOS button doesn\'t distinguish between types.');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: V26.paper2,
        border: Border.all(color: V26.navy100),
        borderRadius: BorderRadius.circular(V26.rMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: V26.navy600,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.info_outline,
                size: 13, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(
                fontFamily: V26.sans,
                fontSize: 13,
                height: 1.5,
                color: V26.ink700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBody(String code, {required bool compact}) {
    final items = <_SummaryRow>[
      _SummaryRow(
        title: code == 'he'
            ? 'תפקיד · ${_optLabel(_roleOpts, _role, code)}'
            : (code == 'ru'
                ? 'Роль · ${_optLabel(_roleOpts, _role, code)}'
                : 'Role · ${_optLabel(_roleOpts, _role, code)}'),
        subtitle: code == 'he'
            ? 'מסך שלך מותאם'
            : (code == 'ru' ? 'Экран адаптирован' : 'Your screen is tailored'),
      ),
      _SummaryRow(
        title: code == 'he'
            ? 'תרחיש · ${_optLabel(_scenarioOpts, _scenario, code)}'
            : (code == 'ru'
                ? 'Сценарий · ${_optLabel(_scenarioOpts, _scenario, code)}'
                : 'Scenario · ${_optLabel(_scenarioOpts, _scenario, code)}'),
        subtitle: code == 'he'
            ? 'זכויות מותאמות'
            : (code == 'ru' ? 'Права подстроены' : 'Rights pre-loaded'),
      ),
      _SummaryRow(
        title: code == 'he'
            ? 'התראות · ${_optLabel(_alertsOpts, _alerts, code)}'
            : (code == 'ru'
                ? 'Уведомления · ${_optLabel(_alertsOpts, _alerts, code)}'
                : 'Alerts · ${_optLabel(_alertsOpts, _alerts, code)}'),
        subtitle: code == 'he'
            ? 'לא תפספס קריאה'
            : (code == 'ru' ? 'Не пропустите вызов' : 'Won\'t miss a call'),
      ),
      _SummaryRow(
        title: code == 'he'
            ? 'פרטיות · ${_optLabel(_privacyOpts, _privacy, code)}'
            : (code == 'ru'
                ? 'Приватность · ${_optLabel(_privacyOpts, _privacy, code)}'
                : 'Privacy · ${_optLabel(_privacyOpts, _privacy, code)}'),
        subtitle: code == 'he'
            ? 'שם נחשף רק אם תאשר'
            : (code == 'ru'
                ? 'Имя — только с согласия'
                : 'Name shown only if you approve'),
      ),
    ];

    return SingleChildScrollView(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 18, 16, 18)
          : const EdgeInsets.fromLTRB(56, 32, 56, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: V26QuizCard(
            title: code == 'he'
                ? 'הכל מוכן'
                : (code == 'ru' ? 'Всё готово' : 'All set'),
            lede: code == 'he'
                ? 'סיכום ההגדרות שלך — תוכל לשנות בכל זמן.'
                : (code == 'ru'
                    ? 'Сводка настроек — можно поменять позже.'
                    : 'Summary of your settings — change any time.'),
            compact: compact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _summaryTile(items[i]),
                ],
                const SizedBox(height: 18),
                _calloutSuccess(code),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _optLabel(List<_Opt> opts, String id, String code) {
    return opts
        .firstWhere((o) => o.id == id, orElse: () => opts.first)
        .t(code);
  }

  Widget _summaryTile(_SummaryRow row) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: V26.surface,
        border: Border.all(color: V26.hairline),
        borderRadius: BorderRadius.circular(V26.rMd),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: V26.ok,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded,
                size: 13, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: V26.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.subtitle,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    fontSize: 12,
                    color: V26.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calloutSuccess(String code) {
    final head = code == 'he'
        ? 'VETO מוכן.'
        : (code == 'ru' ? 'VETO готов.' : 'VETO is ready.');
    final body = code == 'he'
        ? 'כפתור ה-SOS שלך פעיל בכל רגע.'
        : (code == 'ru'
            ? 'Ваша кнопка SOS активна в любой момент.'
            : 'Your SOS button is active at all times.');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFCF6),
        border: Border.all(color: V26.ok.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(V26.rMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: V26.ok,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded,
                size: 13, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: V26.sans,
                  fontSize: 13,
                  height: 1.5,
                  color: V26.ink900,
                ),
                children: [
                  TextSpan(
                    text: '$head ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String title;
  final String subtitle;
  const _SummaryRow({required this.title, required this.subtitle});
}
