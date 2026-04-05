import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_language.dart';
import '../core/theme/future_surface.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../widgets/app_language_menu.dart';

enum AuthWizardStep { role, profile, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthWizardStep _step = AuthWizardStep.role;
  String _role = 'user';
  bool _registerMode = false;
  bool _loading = false;
  String _error = '';
  final String _countryCode = '+972';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneLocalController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  static const Map<String, Map<String, String>> _copy = {
    'he': {
      'heroEyebrow': 'אשף התחברות והרשמה',
      'heroTitle': 'כניסה ברורה. הרשמה מהירה. שפה אחת שנשמרת איתך.',
      'heroBody': 'מסלול קצר שמגדיר תפקיד, שפה מועדפת ואימות טלפון בלי מסכים עמוסים ובלי צעדים מיותרים.',
      'proof1': 'אזרח, עורך דין או מנהל',
      'proof2': 'עברית, אנגלית ורוסית',
      'proof3': 'OTP ואימות מנוי באותו רצף',
      'heroTagline': 'ממשק כניסה מאוחד לכל התפקידים',
      'stepRole': 'סוג חשבון',
      'stepProfile': 'פרטים',
      'stepOtp': 'אימות',
      'chooseRole': 'בחר איך אתה נכנס ל-VETO',
      'chooseRoleBody': 'הבחירה כאן קובעת את הזרימה, את הדשבורד ואת שפת העבודה שתישמר בהמשך.',
      'citizenTitle': 'אזרח',
      'citizenBody': 'סיוע משפטי מיידי, AI, תרחישים, SOS ותיעוד ראיות.',
      'lawyerTitle': 'עורך דין',
      'lawyerBody': 'קבלת קריאות, שליטה בזמינות וניהול תיקים מהמסך הייעודי שלך.',
      'next': 'המשך',
      'login': 'כניסה',
      'register': 'הרשמה',
      'profileTitle': 'פרטי החשבון',
      'profileBody': 'הזן את הטלפון שלך. בהרשמה נוסיף גם שם מלא ונשמור את השפה שבחרת.',
      'fullName': 'שם מלא',
      'phoneLabel': 'מספר טלפון',
      'phoneHint': 'אפשר להזין 05X-XXXXXXX או 5XXXXXXXX',
      'back': 'חזור',
      'sendOtp': 'שלח קוד אימות',
      'otpTitle': 'אימות טלפון',
      'otpBody': 'הקוד נשלח ל-',
      'verify': 'אמת והמשך',
      'invalidPhone': 'נא להזין מספר טלפון תקין בן 9–10 ספרות.',
      'missingName': 'נא להזין שם מלא כדי להשלים הרשמה.',
      'registerFailed': 'לא הצלחנו לפתוח חשבון חדש. נסה שוב בעוד רגע.',
      'otpFailed': 'שליחת קוד האימות נכשלה. ודא שהחשבון קיים או עבור להרשמה.',
      'systemError': 'אירעה שגיאה זמנית. נסה שוב בעוד כמה שניות.',
      'otpInvalid': 'קוד האימות שהוזן אינו תקין.',
      'otpIncomplete': 'יש להזין קוד מלא בן 6 ספרות.',
      'pendingTitle': 'הבקשה ממתינה לאישור',
      'pendingBody': 'חשבון עורך הדין שלך נוצר ונשלח לבדיקת מנהל מערכת. לאחר האישור תוכל להתחבר למסך הייעודי שלך.',
      'otpDialogTitle': 'קוד האימות שלך',
      'otpDialogBody': 'שירות SMS אינו זמין כרגע. זהו הקוד הזמני שלך:',
      'understood': 'הבנתי',
      'subscriptionTitle': 'הצטרפות מלאה ל-VETO',
      'subscriptionBody': 'כדי להשתמש במערכת המלאה יש להפעיל מנוי חודשי. תשלום עורך דין חירום מחויב רק בעת שימוש.',
      'subscriptionPlan': 'מנוי חודשי',
      'subscriptionPrice': '₪19.90 / חודש',
      'subscriptionLine1': 'AI משפטי ללא הגבלה',
      'subscriptionLine2': 'גישה לתרחישים, זכויות ותיעוד',
      'subscriptionLine3': 'הזנקת עורך דין בתשלום נפרד לפי אירוע',
      'later': 'לא עכשיו',
      'paypal': 'מעבר ל-PayPal',
      'paymentOpened': 'סיימת ב-PayPal? חזור לכאן ולחץ אישור תשלום.',
      'paymentConfirm': 'אישור תשלום',
      'paymentOpenFailed': 'לא ניתן לפתוח את PayPal כרגע. נסה שוב.',
      'paymentConfirmFailed': 'התשלום עדיין לא אושר. בדוק את חלון PayPal ונסה שוב.',
    },
    'en': {
      'heroEyebrow': 'Sign-in and registration wizard',
      'heroTitle': 'Clear sign-in. Fast onboarding. One language that stays with you.',
      'heroBody': 'A short flow that sets your role, preferred language, and phone verification without clutter or unnecessary steps.',
      'proof1': 'Citizen, lawyer, or admin flow',
      'proof2': 'Hebrew, English, and Russian',
      'proof3': 'OTP and subscription handling in one sequence',
      'heroTagline': 'One access layer for every role',
      'stepRole': 'Account type',
      'stepProfile': 'Details',
      'stepOtp': 'Verification',
      'chooseRole': 'Choose how you enter VETO',
      'chooseRoleBody': 'This choice controls the flow, dashboard, and working language saved for later.',
      'citizenTitle': 'Citizen',
      'citizenBody': 'Immediate legal guidance, AI assistance, scenarios, SOS, and evidence capture.',
      'lawyerTitle': 'Lawyer',
      'lawyerBody': 'Receive alerts, control availability, and handle cases from your dedicated console.',
      'next': 'Continue',
      'login': 'Sign in',
      'register': 'Register',
      'profileTitle': 'Account details',
      'profileBody': 'Enter your phone number. Registration also collects your full name and saves your selected language.',
      'fullName': 'Full name',
      'phoneLabel': 'Phone number',
      'phoneHint': 'You can type 05X-XXXXXXX or 5XXXXXXXX',
      'back': 'Back',
      'sendOtp': 'Send code',
      'otpTitle': 'Phone verification',
      'otpBody': 'A code was sent to ',
      'verify': 'Verify and continue',
      'invalidPhone': 'Please enter a valid 9–10 digit phone number.',
      'missingName': 'Please enter your full name to complete registration.',
      'registerFailed': 'We could not create your account. Please try again shortly.',
      'otpFailed': 'We could not send a verification code. Make sure the account exists or switch to registration.',
      'systemError': 'A temporary error occurred. Please try again in a moment.',
      'otpInvalid': 'The verification code is not valid.',
      'otpIncomplete': 'Please enter all 6 digits.',
      'pendingTitle': 'Approval pending',
      'pendingBody': 'Your lawyer account was created and sent to the admin for review. Once approved, you will be able to enter your dedicated dashboard.',
      'otpDialogTitle': 'Your verification code',
      'otpDialogBody': 'SMS is currently unavailable. Use this temporary code:',
      'understood': 'Understood',
      'subscriptionTitle': 'Activate full VETO access',
      'subscriptionBody': 'A monthly membership is required for the full platform. Emergency lawyer dispatch is billed only when you trigger a live event.',
      'subscriptionPlan': 'Monthly membership',
      'subscriptionPrice': '₪19.90 / month',
      'subscriptionLine1': 'Unlimited legal AI',
      'subscriptionLine2': 'Access to scenarios, rights, and evidence tools',
      'subscriptionLine3': 'Emergency lawyer dispatch billed separately per event',
      'later': 'Maybe later',
      'paypal': 'Open PayPal',
      'paymentOpened': 'Finished in PayPal? Return here and confirm the payment.',
      'paymentConfirm': 'Confirm payment',
      'paymentOpenFailed': 'PayPal could not be opened right now. Please try again.',
      'paymentConfirmFailed': 'The payment is not confirmed yet. Check the PayPal tab and try again.',
    },
    'ru': {
      'heroEyebrow': 'Мастер входа и регистрации',
      'heroTitle': 'Понятный вход. Быстрая регистрация. Один язык, который остается с вами.',
      'heroBody': 'Короткий сценарий, который задает роль, предпочитаемый язык и подтверждение телефона без лишних экранов и шагов.',
      'proof1': 'Сценарий для гражданина, адвоката и администратора',
      'proof2': 'Иврит, английский и русский',
      'proof3': 'OTP и подписка в одном потоке',
      'heroTagline': 'Единый вход для всех ролей',
      'stepRole': 'Тип аккаунта',
      'stepProfile': 'Детали',
      'stepOtp': 'Проверка',
      'chooseRole': 'Выберите, как вы входите в VETO',
      'chooseRoleBody': 'Этот выбор определяет поток, панель и рабочий язык, который будет сохранен дальше.',
      'citizenTitle': 'Гражданин',
      'citizenBody': 'Немедленная юридическая помощь, AI, сценарии, SOS и фиксация доказательств.',
      'lawyerTitle': 'Адвокат',
      'lawyerBody': 'Получение запросов, управление доступностью и работа с делами в отдельной панели.',
      'next': 'Продолжить',
      'login': 'Вход',
      'register': 'Регистрация',
      'profileTitle': 'Данные аккаунта',
      'profileBody': 'Введите номер телефона. При регистрации мы также сохраняем полное имя и выбранный язык.',
      'fullName': 'Полное имя',
      'phoneLabel': 'Номер телефона',
      'phoneHint': 'Можно вводить 05X-XXXXXXX или 5XXXXXXXX',
      'back': 'Назад',
      'sendOtp': 'Отправить код',
      'otpTitle': 'Проверка телефона',
      'otpBody': 'Код отправлен на ',
      'verify': 'Подтвердить и продолжить',
      'invalidPhone': 'Введите корректный номер телефона из 9–10 цифр.',
      'missingName': 'Введите полное имя, чтобы завершить регистрацию.',
      'registerFailed': 'Не удалось создать аккаунт. Попробуйте еще раз чуть позже.',
      'otpFailed': 'Не удалось отправить код. Убедитесь, что аккаунт существует, или переключитесь на регистрацию.',
      'systemError': 'Произошла временная ошибка. Попробуйте еще раз через несколько секунд.',
      'otpInvalid': 'Код подтверждения недействителен.',
      'otpIncomplete': 'Введите все 6 цифр.',
      'pendingTitle': 'Ожидается одобрение',
      'pendingBody': 'Ваш аккаунт адвоката создан и отправлен администратору на проверку. После одобрения вы сможете войти в свою панель.',
      'otpDialogTitle': 'Ваш код подтверждения',
      'otpDialogBody': 'SMS сейчас недоступны. Используйте этот временный код:',
      'understood': 'Понятно',
      'subscriptionTitle': 'Полный доступ к VETO',
      'subscriptionBody': 'Для полного доступа к платформе требуется ежемесячная подписка. Вызов адвоката оплачивается только при живой эскалации.',
      'subscriptionPlan': 'Ежемесячная подписка',
      'subscriptionPrice': '₪19.90 / месяц',
      'subscriptionLine1': 'Неограниченный юридический AI',
      'subscriptionLine2': 'Доступ к сценариям, правам и доказательствам',
      'subscriptionLine3': 'Экстренный вызов адвоката оплачивается отдельно за событие',
      'later': 'Позже',
      'paypal': 'Открыть PayPal',
      'paymentOpened': 'Закончили в PayPal? Вернитесь сюда и подтвердите платеж.',
      'paymentConfirm': 'Подтвердить платеж',
      'paymentOpenFailed': 'PayPal сейчас не открывается. Попробуйте позже.',
      'paymentConfirmFailed': 'Платеж еще не подтвержден. Проверьте вкладку PayPal и попробуйте снова.',
    },
  };

  String get _fullPhone {
    // Strip non-digits first, then remove leading 0 to produce +972XXXXXXXXX
    final digits = _phoneLocalController.text.trim().replaceAll(RegExp(r'\D'), '');
    final normalized = digits.startsWith('0') ? digits.substring(1) : digits;
    return '$_countryCode$normalized';
  }

  String _t(String code, String key) {
    return _copy[AppLanguage.normalize(code)]?[key] ??
        _copy[AppLanguage.hebrew]![key] ??
        key;
  }

  Future<void> _continueFromProfile() async {
    final lang = context.read<AppLanguageController>().code;
    final local = _phoneLocalController.text.trim();
    final digitsOnly = local.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 9 || digitsOnly.length > 10) {
      setState(() => _error = _t(lang, 'invalidPhone'));
      return;
    }
    if (_registerMode && _nameController.text.trim().isEmpty) {
      setState(() => _error = _t(lang, 'missingName'));
      return;
    }

    final phone = _fullPhone;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      if (_registerMode) {
        final ok = await AuthService().register(
          fullName: _nameController.text.trim(),
          phoneNumber: phone,
          role: _role,
          language: lang,
        );
        if (!ok) {
          setState(() {
            _loading = false;
            _error = _t(lang, 'registerFailed');
          });
          return;
        }
      }

      final otp = await AuthService().requestOTPDetailed(phone, _role);
      if (!mounted) return;
      if (otp == 'error') {
        setState(() {
          _loading = false;
          _error = _t(lang, 'otpFailed');
        });
        return;
      }

      setState(() {
        _loading = false;
        _step = AuthWizardStep.otp;
      });

      if (otp != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => _OtpCodeDialog(code: lang, otp: otp, t: _t),
        );
      }
    } catch (_) {
      setState(() {
        _loading = false;
        _error = _t(lang, 'systemError');
      });
    }
  }

  Future<void> _verifyOtp(String otp) async {
    final lang = context.read<AppLanguageController>().code;
    setState(() {
      _loading = true;
      _error = '';
    });

    final data = await AuthService().verifyOTP(_fullPhone, otp);
    if (!mounted) return;

    if (data != null) {
      if (data['pending_approval'] == true) {
        await showDialog<void>(
          context: context,
          builder: (_) => _PendingApprovalDialog(code: lang, t: _t),
        );
        setState(() => _loading = false);
        return;
      }

      final role = data['user']?['role']?.toString() ??
          await AuthService().getStoredRole() ??
          _role;
      final preferredLanguage = AppLanguage.normalize(
        data['user']?['preferred_language']?.toString() ?? lang,
      );
      await context
          .read<AppLanguageController>()
          .setLanguage(preferredLanguage, persist: false);

      if (!mounted) return;
      if (role == 'lawyer') {
        Navigator.of(context).pushReplacementNamed('/lawyer_dashboard');
      } else if (role == 'admin') {
        Navigator.of(context).pushReplacementNamed('/admin_settings');
      } else {
        final isPaymentExempt = data['user']?['is_payment_exempt'] == true;
        final isSubscribed = data['user']?['is_subscribed'] == true;
        if (isPaymentExempt || isSubscribed) {
          Navigator.of(context).pushReplacementNamed('/veto_screen');
        } else {
          final subscribed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                _SubscriptionGateDialog(code: preferredLanguage, t: _t),
          );
          if (subscribed == true && mounted) {
            Navigator.of(context).pushReplacementNamed('/veto_screen');
          }
        }
      }
      return;
    }

    setState(() {
      _loading = false;
      _error = _t(lang, 'otpInvalid');
    });
  }

  Future<void> _submitOtp() async {
    final code = _otpController.text.trim();
    final lang = context.read<AppLanguageController>().code;
    if (code.length != 6) {
      setState(() => _error = _t(lang, 'otpIncomplete'));
      return;
    }
    await _verifyOtp(code);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneLocalController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguageController>();
    final code = language.code;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 980;

              return Row(
                children: [
                  if (wide)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
                        child: _AuthHero(
                          eyebrow: _t(code, 'heroEyebrow'),
                          title: _t(code, 'heroTitle'),
                          body: _t(code, 'heroBody'),
                          proof1: _t(code, 'proof1'),
                          proof2: _t(code, 'proof2'),
                          proof3: _t(code, 'proof3'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 12 : 24,
                            24,
                            wide ? 24 : 24,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!wide) ...[
                                _AuthHero(
                                  eyebrow: _t(code, 'heroEyebrow'),
                                  title: _t(code, 'heroTitle'),
                                  body: _t(code, 'heroBody'),
                                  proof1: _t(code, 'proof1'),
                                  proof2: _t(code, 'proof2'),
                                  proof3: _t(code, 'proof3'),
                                  compact: true,
                                ),
                                const SizedBox(height: 16),
                              ],
                              const Row(
                                children: [
                                  Spacer(),
                                  AppLanguageMenu(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GlassPanel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _BrandHeader(tagline: _t(code, 'heroTagline')),
                                    const SizedBox(height: 22),
                                    _StepBar(
                                      labels: [
                                        _t(code, 'stepRole'),
                                        _t(code, 'stepProfile'),
                                        _t(code, 'stepOtp'),
                                      ],
                                      currentStep: _step.index,
                                    ),
                                    const SizedBox(height: 24),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 280),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: _stepBody(code),
                                    ),
                                  ],
                                ),
                              ),
                              if (_error.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: VetoPalette.emergency.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: VetoPalette.emergency.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          color: VetoPalette.emergency, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error,
                                          style: const TextStyle(
                                            color: VetoPalette.emergency,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stepBody(String code) {
    switch (_step) {
      case AuthWizardStep.role:
        return _roleStep(code);
      case AuthWizardStep.profile:
        return _profileStep(code);
      case AuthWizardStep.otp:
        return _otpStep(code);
    }
  }

  Widget _roleStep(String code) {
    return Column(
      key: const ValueKey('roleStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t(code, 'chooseRole'),
          style: const TextStyle(
            color: VetoPalette.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _t(code, 'chooseRoleBody'),
          style: const TextStyle(
            color: VetoPalette.textMuted,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                selected: _role == 'user',
                icon: Icons.person_search_outlined,
                title: _t(code, 'citizenTitle'),
                body: _t(code, 'citizenBody'),
                onTap: () => setState(() => _role = 'user'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                selected: _role == 'lawyer',
                icon: Icons.gavel_rounded,
                title: _t(code, 'lawyerTitle'),
                body: _t(code, 'lawyerBody'),
                onTap: () => setState(() => _role = 'lawyer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => setState(() => _step = AuthWizardStep.profile),
          child: Text(_t(code, 'next')),
        ),
      ],
    );
  }

  Widget _profileStep(String code) {
    return Column(
      key: const ValueKey('profileStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: VetoPalette.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VetoPalette.border),
          ),
          child: Row(
            children: [
              _ModeTab(
                label: _t(code, 'login'),
                selected: !_registerMode,
                onTap: () => setState(() => _registerMode = false),
              ),
              _ModeTab(
                label: _t(code, 'register'),
                selected: _registerMode,
                onTap: () => setState(() => _registerMode = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _t(code, 'profileTitle'),
          style: const TextStyle(
            color: VetoPalette.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _t(code, 'profileBody'),
          style: const TextStyle(
            color: VetoPalette.textMuted,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        if (_registerMode) ...[
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            decoration: InputDecoration(
              labelText: _t(code, 'fullName'),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _t(code, 'phoneLabel'),
          style: const TextStyle(
            color: VetoPalette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: VetoPalette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VetoPalette.border),
              ),
              child: Text(
                _countryCode,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: VetoPalette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneLocalController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.go,
                textDirection: TextDirection.ltr,
                maxLength: 10,
                onSubmitted: (_) {
                  if (!_loading) _continueFromProfile();
                },
                decoration: const InputDecoration(
                  hintText: '05X-XXXXXXX',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_iphone_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _t(code, 'phoneHint'),
          style: const TextStyle(
            color: VetoPalette.textSubtle,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = AuthWizardStep.role),
                child: Text(_t(code, 'back')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _loading ? null : _continueFromProfile,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_t(code, 'sendOtp')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _otpStep(String code) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 58,
      textStyle: const TextStyle(
        color: VetoPalette.text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VetoPalette.border),
      ),
    );

    return Column(
      key: const ValueKey('otpStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t(code, 'otpTitle'),
          style: const TextStyle(
            color: VetoPalette.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _t(code, 'otpBody'),
              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              _fullPhone,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: VetoPalette.info, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Center(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Pinput(
              controller: _otpController,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration?.copyWith(
                  border: Border.all(color: VetoPalette.primary, width: 1.5),
                ),
              ),
              onChanged: (_) {
                if (_error.isNotEmpty) {
                  setState(() => _error = '');
                }
              },
              onCompleted: _verifyOtp,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _step = AuthWizardStep.profile),
                child: Text(_t(code, 'back')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
              onPressed: _loading ? null : _submitOtp,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_t(code, 'verify')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final String tagline;

  const _BrandHeader({required this.tagline});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: VetoPalette.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.32)),
          ),
          child: const Icon(Icons.shield_rounded,
              color: VetoPalette.primary, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VETO',
                style: TextStyle(
                  color: VetoPalette.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              Text(
                tagline,
                style: const TextStyle(
                  color: VetoPalette.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  final List<String> labels;
  final int currentStep;

  const _StepBar({required this.labels, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index < labels.length - 1 ? 8 : 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: active ? VetoPalette.primary : VetoPalette.border,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? VetoPalette.primary : VetoPalette.textSubtle,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? VetoPalette.primary.withValues(alpha: 0.12)
              : VetoPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? VetoPalette.primary : VetoPalette.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? VetoPalette.primary : VetoPalette.textMuted,
                size: 26),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: selected ? VetoPalette.primary : VetoPalette.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: VetoPalette.textMuted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? VetoPalette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : VetoPalette.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final String proof1;
  final String proof2;
  final String proof3;
  final bool compact;

  const _AuthHero({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.proof1,
    required this.proof2,
    required this.proof3,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF132645), Color(0xFF101D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: VetoPalette.border),
      ),
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
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: VetoPalette.text,
              fontSize: compact ? 28 : 46,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: const TextStyle(
              color: VetoPalette.textMuted,
              fontSize: 15,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          _HeroLine(icon: Icons.account_tree_outlined, label: proof1),
          const SizedBox(height: 10),
          _HeroLine(icon: Icons.translate_rounded, label: proof2),
          const SizedBox(height: 10),
          _HeroLine(icon: Icons.auto_awesome_rounded, label: proof3),
        ],
      ),
    );
  }
}

class _HeroLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: VetoPalette.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: VetoPalette.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpCodeDialog extends StatelessWidget {
  final String code;
  final String otp;
  final String Function(String, String) t;

  const _OtpCodeDialog({
    required this.code,
    required this.otp,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t(code, 'otpDialogTitle'),
          style: const TextStyle(color: VetoPalette.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t(code, 'otpDialogBody'),
              style: const TextStyle(color: VetoPalette.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              otp,
              style: const TextStyle(
                color: VetoPalette.primary,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t(code, 'understood')),
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalDialog extends StatelessWidget {
  final String code;
  final String Function(String, String) t;

  const _PendingApprovalDialog({required this.code, required this.t});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t(code, 'pendingTitle'),
          style: const TextStyle(color: VetoPalette.text),
        ),
        content: Text(
          t(code, 'pendingBody'),
          style: const TextStyle(color: VetoPalette.textMuted, height: 1.6),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t(code, 'understood')),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionGateDialog extends StatefulWidget {
  final String code;
  final String Function(String, String) t;

  const _SubscriptionGateDialog({required this.code, required this.t});

  @override
  State<_SubscriptionGateDialog> createState() =>
      _SubscriptionGateDialogState();
}

class _SubscriptionGateDialogState extends State<_SubscriptionGateDialog> {
  bool _loading = false;
  String? _error;
  String? _orderId;

  Future<void> _openPayPal() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final orderId = await PaymentService.createAndOpenOrder(
      PaymentType.subscription,
    );
    if (!mounted) return;
    if (orderId == null) {
      setState(() {
        _loading = false;
        _error = widget.t(widget.code, 'paymentOpenFailed');
      });
      return;
    }
    setState(() {
      _loading = false;
      _orderId = orderId;
    });
  }

  Future<void> _confirmPayment() async {
    if (_orderId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final phone = await AuthService().getStoredPhone();
    final result = await PaymentService.captureOrder(
      orderId: _orderId!,
      type: PaymentType.subscription,
      userId: phone,
    );
    if (!mounted) return;
    if (result.success) {
      await AuthService().setSubscribed(true);
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _loading = false;
      _error = result.error ?? widget.t(widget.code, 'paymentConfirmFailed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLanguage.directionOf(widget.code),
      child: AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.lock_open_rounded, color: VetoPalette.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.t(widget.code, 'subscriptionTitle'),
                style: const TextStyle(
                  color: VetoPalette.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.t(widget.code, 'subscriptionBody'),
              style: const TextStyle(
                color: VetoPalette.textMuted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VetoPalette.bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: VetoPalette.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.t(widget.code, 'subscriptionPlan'),
                    style: const TextStyle(
                      color: VetoPalette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.t(widget.code, 'subscriptionPrice'),
                    style: const TextStyle(
                      color: VetoPalette.success,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PlanLine(text: widget.t(widget.code, 'subscriptionLine1')),
                  _PlanLine(text: widget.t(widget.code, 'subscriptionLine2')),
                  _PlanLine(text: widget.t(widget.code, 'subscriptionLine3')),
                ],
              ),
            ),
            if (_orderId != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.t(widget.code, 'paymentOpened'),
                style: const TextStyle(color: VetoPalette.warning),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: VetoPalette.emergency),
              ),
            ],
          ],
        ),
        actions: _orderId == null
            ? [
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    widget.t(widget.code, 'later'),
                    style: const TextStyle(color: VetoPalette.textMuted),
                  ),
                ),
                FilledButton(
                  onPressed: _loading ? null : _openPayPal,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF009CDE),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.t(widget.code, 'paypal')),
                ),
              ]
            : [
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    widget.t(widget.code, 'later'),
                    style: const TextStyle(color: VetoPalette.textMuted),
                  ),
                ),
                FilledButton(
                  onPressed: _loading ? null : _confirmPayment,
                  style: FilledButton.styleFrom(
                    backgroundColor: VetoPalette.success,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.t(widget.code, 'paymentConfirm')),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: VetoPalette.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: VetoPalette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}