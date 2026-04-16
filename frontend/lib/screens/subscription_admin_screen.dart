// ============================================================
//  SubscriptionAdminScreen.dart — Admin subscription management
//  Shows all subscriptions, revenue summary, manual controls
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';

// ── i18n ──────────────────────────────────────────────────────
const _i18n = {
  'he': {
    'title': 'משתמשים ומנויים',
    'tabUsers': 'כל המשתמשים',
    'tabLogs': 'לוג כניסות',
    'revenue': 'הכנסות',
    'total': 'סה"כ משתמשים',
    'active': 'מנויים פעילים',
    'expired': 'פגי תוקף',
    'cancelled': 'בוטלו',
    'monthly': 'הכנסה חודשית',
    'allTime': 'סה"כ הכנסות',
    'user': 'משתמש',
    'plan': 'תוכנית',
    'status': 'סטטוס',
    'startDate': 'הצטרף',
    'endDate': 'פקיעה',
    'amount': 'סכום',
    'actions': 'פעולות',
    'activate': 'הפעל',
    'cancel': 'בטל',
    'extend': 'הארך 30 יום',
    'search': 'חיפוש לפי שם/מייל/טלפון',
    'noSubs': 'אין משתמשים',
    'noLogs': 'אין לוג',
    'loading': 'טוען...',
    'refresh': 'רענן',
    'statusActive': 'מנוי פעיל',
    'statusExpired': 'פג תוקף',
    'statusCancelled': 'בוטל',
    'statusTrial': 'ניסיון',
    'statusFree': 'חינמי',
    'statusNoSub': 'ללא מנוי',
    'statusUnverified': 'לא מאומת',
    'planFree': 'חינמי',
    'planBasic': 'בסיסי',
    'planPro': 'מקצועי',
    'planNone': 'ללא',
    'confirmCancel': 'לבטל מנוי זה?',
    'confirmActivate': 'להפעיל מנוי זה?',
    'confirmExtend': 'להאריך ב-30 יום?',
    'confirmDeleteUser': 'למחוק משתמש זה לצמיתות? פעולה בלתי הפיכה.',
    'yes': 'כן',
    'no': 'לא',
    'updated': 'עודכן',
    'edit': 'עריכה',
    'delete': 'מחיקה',
    'save': 'שמור',
    'deleted': 'נמחק',
    'errorSave': 'שגיאה',
    'fullName': 'שם מלא',
    'phoneLabel': 'טלפון',
    'emailLabel': 'אימייל',
    'subscriptionExpiry': 'תאריך פקיעת מנוי',
    'subscribed': 'מנוי פעיל',
    'manualExempt': 'פטור ידני (מנהל)',
    'accountEnabled': 'חשבון פעיל',
    'clearExpiry': 'נקה תאריך',
    'logSuccess': 'הצליח',
    'logFail': 'נכשל',
    'logRegister': 'הרשמה',
    'logOtpReq': 'בקשת OTP',
    'logOtpOk': 'OTP אושר',
    'logOtpFail': 'OTP נכשל',
    'logGoogle': 'Google כניסה',
    'logGoogleFail': 'Google נכשל',
  },
  'en': {
    'title': 'Users & Subscriptions',
    'tabUsers': 'All Users',
    'tabLogs': 'Login Logs',
    'revenue': 'Revenue',
    'total': 'Total Users',
    'active': 'Active Subscribers',
    'expired': 'Expired',
    'cancelled': 'Cancelled',
    'monthly': 'Monthly Revenue',
    'allTime': 'Total Revenue',
    'user': 'User',
    'plan': 'Plan',
    'status': 'Status',
    'startDate': 'Joined',
    'endDate': 'Expires',
    'amount': 'Amount',
    'actions': 'Actions',
    'activate': 'Activate',
    'cancel': 'Cancel',
    'extend': 'Extend 30d',
    'search': 'Search by name/email/phone',
    'noSubs': 'No users found',
    'noLogs': 'No logs',
    'loading': 'Loading...',
    'refresh': 'Refresh',
    'statusActive': 'Active',
    'statusExpired': 'Expired',
    'statusCancelled': 'Cancelled',
    'statusTrial': 'Trial',
    'statusFree': 'Free',
    'statusNoSub': 'No Subscription',
    'statusUnverified': 'Unverified',
    'planFree': 'Free',
    'planBasic': 'Basic',
    'planPro': 'Pro',
    'planNone': 'None',
    'confirmCancel': 'Cancel this subscription?',
    'confirmActivate': 'Activate this subscription?',
    'confirmExtend': 'Extend by 30 days?',
    'confirmDeleteUser': 'Delete this user permanently? This cannot be undone.',
    'yes': 'Yes',
    'no': 'No',
    'updated': 'Updated',
    'edit': 'Edit',
    'delete': 'Delete',
    'save': 'Save',
    'deleted': 'Deleted',
    'errorSave': 'Error',
    'fullName': 'Full name',
    'phoneLabel': 'Phone',
    'emailLabel': 'Email',
    'subscriptionExpiry': 'Subscription expiry',
    'subscribed': 'Subscribed',
    'manualExempt': 'Manual exempt (admin)',
    'accountEnabled': 'Account active',
    'clearExpiry': 'Clear expiry',
    'logSuccess': 'Success',
    'logFail': 'Failed',
    'logRegister': 'Register',
    'logOtpReq': 'OTP Request',
    'logOtpOk': 'OTP Verified',
    'logOtpFail': 'OTP Failed',
    'logGoogle': 'Google Login',
    'logGoogleFail': 'Google Failed',
  },
  'ru': {
    'title': 'Пользователи и подписки',
    'tabUsers': 'Все пользователи',
    'tabLogs': 'Журнал входов',
    'revenue': 'Доход',
    'total': 'Всего',
    'active': 'Активных',
    'expired': 'Истекших',
    'cancelled': 'Отменённых',
    'monthly': 'Ежемесячный доход',
    'allTime': 'Общий доход',
    'user': 'Пользователь',
    'plan': 'Тариф',
    'status': 'Статус',
    'startDate': 'Зарегистрирован',
    'endDate': 'Истекает',
    'amount': 'Сумма',
    'actions': 'Действия',
    'activate': 'Активировать',
    'cancel': 'Отменить',
    'extend': 'Продлить 30д',
    'search': 'Поиск по имени/email/тел.',
    'noSubs': 'Нет пользователей',
    'noLogs': 'Нет записей',
    'loading': 'Загрузка...',
    'refresh': 'Обновить',
    'statusActive': 'Активна',
    'statusExpired': 'Истекла',
    'statusCancelled': 'Отменена',
    'statusTrial': 'Пробная',
    'statusFree': 'Бесплатный',
    'statusNoSub': 'Без подписки',
    'statusUnverified': 'Не подтверждён',
    'planFree': 'Бесплатный',
    'planBasic': 'Базовый',
    'planPro': 'Pro',
    'planNone': 'Нет',
    'confirmCancel': 'Отменить подписку?',
    'confirmActivate': 'Активировать?',
    'confirmExtend': 'Продлить на 30 дней?',
    'confirmDeleteUser': 'Удалить этого пользователя навсегда?',
    'yes': 'Да',
    'no': 'Нет',
    'updated': 'Обновлено',
    'edit': 'Изменить',
    'delete': 'Удалить',
    'save': 'Сохранить',
    'deleted': 'Удалено',
    'errorSave': 'Ошибка',
    'fullName': 'Имя',
    'phoneLabel': 'Телефон',
    'emailLabel': 'Email',
    'subscriptionExpiry': 'Окончание подписки',
    'subscribed': 'Подписка',
    'manualExempt': 'Вручную (админ)',
    'accountEnabled': 'Аккаунт активен',
    'clearExpiry': 'Сброс даты',
    'logSuccess': 'Успех',
    'logFail': 'Ошибка',
    'logRegister': 'Регистрация',
    'logOtpReq': 'Запрос OTP',
    'logOtpOk': 'OTP принят',
    'logOtpFail': 'OTP ошибка',
    'logGoogle': 'Вход Google',
    'logGoogleFail': 'Google ошибка',
  },
};

String _t(String code, String key) =>
    (_i18n[code] ?? _i18n['en']!)[key] ?? key;

// ── Data model ────────────────────────────────────────────────
class _Sub {
  final String id, userId, userEmail, userName, phone, plan, status;
  final double amount;
  final DateTime? startDate, endDate;
  final bool isSubscribed;
  final bool manuallyAdded;
  final bool isActive;

  const _Sub({
    required this.id, required this.userId, required this.userEmail,
    required this.userName, required this.phone, required this.plan,
    required this.status, required this.amount,
    this.startDate, this.endDate,
    this.isSubscribed = false,
    this.manuallyAdded = false,
    this.isActive = true,
  });

  factory _Sub.fromJson(Map<String, dynamic> j) {
    // Support both subscription-style and user-with-status style
    final user = j['user'] as Map<String, dynamic>? ?? {};
    final isUserFormat = j['computed_status'] != null;
    return _Sub(
      id:       j['_id'] ?? j['id'] ?? '',
      userId:   isUserFormat ? (j['_id'] ?? '') : (user['_id'] ?? j['userId'] ?? ''),
      userEmail:isUserFormat ? (j['email'] ?? '') : (user['email'] ?? j['email'] ?? ''),
      userName: isUserFormat ? (j['full_name'] ?? '') : (user['name'] ?? user['full_name'] ?? j['userName'] ?? ''),
      phone:    j['phone'] ?? user['phone'] ?? '',
      plan:     isUserFormat
          ? (j['manually_added'] == true ? 'free' : (j['is_subscribed'] == true ? 'pro' : 'none'))
          : (j['plan'] ?? 'free'),
      status:   isUserFormat ? (j['computed_status'] ?? 'no_subscription') : (j['status'] ?? 'active'),
      amount:   ((j['amount'] ?? j['price'] ?? 0) as num).toDouble(),
      startDate:DateTime.tryParse(j['startDate'] ?? j['createdAt'] ?? ''),
      endDate:  DateTime.tryParse(j['endDate'] ?? j['subscription_expiry'] ?? j['expiresAt'] ?? ''),
      isSubscribed: j['is_subscribed'] == true,
      manuallyAdded: j['manually_added'] == true,
      isActive: j['is_active'] != false,
    );
  }

  Color get statusColor {
    switch (status) {
      case 'active': return VetoPalette.success;
      case 'free': return VetoPalette.accentSky;
      case 'trial': return VetoPalette.accentSky;
      case 'expired': return VetoPalette.warning;
      case 'cancelled': return VetoPalette.emergency;
      case 'no_subscription': return VetoPalette.textMuted;
      case 'unverified': return VetoPalette.textMuted;
      default: return VetoPalette.textMuted;
    }
  }

  String statusLabel(String code) {
    switch (status) {
      case 'active': return _t(code, 'statusActive');
      case 'free': return _t(code, 'statusFree');
      case 'trial': return _t(code, 'statusTrial');
      case 'expired': return _t(code, 'statusExpired');
      case 'cancelled': return _t(code, 'statusCancelled');
      case 'no_subscription': return _t(code, 'statusNoSub');
      case 'unverified': return _t(code, 'statusUnverified');
      default: return status;
    }
  }

  String planLabel(String code) {
    switch (plan) {
      case 'free': return _t(code, 'planFree');
      case 'basic': return _t(code, 'planBasic');
      case 'pro': return _t(code, 'planPro');
      case 'none': return _t(code, 'planNone');
      default: return plan;
    }
  }
}

// ── Login log ─────────────────────────────────────────────────
class _LoginLog {
  final String id, event;
  final String? phone, email, role, ip, errorMsg;
  final bool success;
  final DateTime createdAt;
  const _LoginLog({required this.id, required this.event, required this.success,
      required this.createdAt, this.phone, this.email, this.role, this.ip, this.errorMsg});

  factory _LoginLog.fromJson(Map<String, dynamic> j) => _LoginLog(
    id:        j['_id'] ?? '',
    event:     j['event'] ?? '',
    success:   j['success'] == true,
    phone:     j['phone'] as String?,
    email:     j['email'] as String?,
    role:      j['role'] as String?,
    ip:        j['ip'] as String?,
    errorMsg:  j['error_msg'] as String?,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );

  String eventLabel(String code) {
    switch (event) {
      case 'register':     return _t(code, 'logRegister');
      case 'otp_request':  return _t(code, 'logOtpReq');
      case 'otp_success':  return _t(code, 'logOtpOk');
      case 'otp_fail':     return _t(code, 'logOtpFail');
      case 'google_login': return _t(code, 'logGoogle');
      case 'google_fail':  return _t(code, 'logGoogleFail');
      default: return event;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────
class SubscriptionAdminScreen extends StatefulWidget {
  const SubscriptionAdminScreen({super.key});

  @override
  State<SubscriptionAdminScreen> createState() =>
      _SubscriptionAdminScreenState();
}

class _SubscriptionAdminScreenState
    extends State<SubscriptionAdminScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabController;

  List<_Sub> _subs = [];
  List<_Sub> _filtered = [];
  List<_LoginLog> _logs = [];
  bool _loading = true;

  double _monthlyRevenue = 0;
  double _totalRevenue = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _subs
          : _subs.where((s) =>
              s.userEmail.toLowerCase().contains(q) ||
              s.userName.toLowerCase().contains(q) ||
              s.phone.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final tok = await _auth.getToken();
      if (tok == null) {
        setState(() { _loading = false; _loadError = 'Not authenticated'; });
        return;
      }
      final headers = AppConfig.httpHeaders({'Authorization': 'Bearer $tok'});

      final usersRes = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/subscriptions'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      final logsRes = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/login-logs?limit=200'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (usersRes.statusCode == 200) {
        final data = jsonDecode(usersRes.body);
        final list = data['users'] ?? data['subscriptions'] ?? (data is List ? data : []);
        _subs = (list as List).map((e) => _Sub.fromJson(e as Map<String, dynamic>)).toList();
        final now = DateTime.now();
        _totalRevenue = _subs.where((s) => s.amount > 0).fold(0, (s, x) => s + x.amount);
        _monthlyRevenue = _subs
            .where((s) => s.status == 'active' && s.startDate?.month == now.month)
            .fold(0, (s, x) => s + x.amount);
      } else {
        _loadError = 'שגיאת שרת: ${usersRes.statusCode}';
      }

      if (logsRes.statusCode == 200) {
        final data = jsonDecode(logsRes.body);
        final list = data['logs'] ?? (data is List ? data : []);
        _logs = (list as List).map((e) => _LoginLog.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _loadError = 'שגיאת חיבור: $e';
    }
    if (mounted) {
      setState(() { _loading = false; });
      _applyFilter();
    }
  }

  String _userApiId(_Sub s) =>
      s.userId.isNotEmpty ? s.userId : s.id;

  Future<void> _putUser(
      String userId, Map<String, dynamic> body, String code) async {
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final res = await http
          .put(
            Uri.parse('${AppConfig.baseUrl}/admin/users/$userId'),
            headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _snack(_t(code, 'updated'));
        await _load();
      } else if (mounted) {
        _snack('${_t(code, 'errorSave')}: ${res.statusCode}', ok: false);
      }
    } catch (e) {
      if (mounted) _snack('${_t(code, 'errorSave')}: $e', ok: false);
    }
  }

  Future<void> _deleteUserApi(String userId, String code) async {
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final res = await http
          .delete(
            Uri.parse('${AppConfig.baseUrl}/admin/users/$userId'),
            headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _snack(_t(code, 'deleted'));
        await _load();
      } else if (mounted) {
        _snack('${_t(code, 'errorSave')}: ${res.statusCode}', ok: false);
      }
    } catch (e) {
      if (mounted) _snack('${_t(code, 'errorSave')}: $e', ok: false);
    }
  }

  Future<void> _openEditDialog(_Sub sub, String code) async {
    final uid = _userApiId(sub);
    if (uid.isEmpty) return;

    final nameCtrl = TextEditingController(text: sub.userName);
    final phoneCtrl = TextEditingController(text: sub.phone);
    final emailCtrl = TextEditingController(text: sub.userEmail);
    var subscribed = sub.isSubscribed;
    var manual = sub.manuallyAdded;
    var active = sub.isActive;
    DateTime? expiry = sub.endDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: Text(_t(code, 'edit'),
              style: const TextStyle(
                  color: VetoPalette.text, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: _t(code, 'fullName'),
                    labelStyle: const TextStyle(color: VetoPalette.textMuted),
                  ),
                  style: const TextStyle(color: VetoPalette.text),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: _t(code, 'phoneLabel'),
                    labelStyle: const TextStyle(color: VetoPalette.textMuted),
                  ),
                  style: const TextStyle(color: VetoPalette.text),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: _t(code, 'emailLabel'),
                    labelStyle: const TextStyle(color: VetoPalette.textMuted),
                  ),
                  style: const TextStyle(color: VetoPalette.text),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_t(code, 'subscribed'),
                      style: const TextStyle(color: VetoPalette.text, fontSize: 14)),
                  trailing: Switch(
                    value: subscribed,
                    onChanged: (v) => setDlg(() => subscribed = v),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_t(code, 'manualExempt'),
                      style: const TextStyle(color: VetoPalette.text, fontSize: 14)),
                  trailing: Switch(
                    value: manual,
                    onChanged: (v) => setDlg(() => manual = v),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_t(code, 'accountEnabled'),
                      style: const TextStyle(color: VetoPalette.text, fontSize: 14)),
                  trailing: Switch(
                    value: active,
                    onChanged: (v) => setDlg(() => active = v),
                  ),
                ),
                Row(children: [
                  Expanded(
                    child: Text(
                      expiry == null
                          ? _t(code, 'subscriptionExpiry')
                          : () {
                              final x = expiry!;
                              return '${_t(code, 'subscriptionExpiry')}: '
                                  '${x.day}/${x.month}/${x.year}';
                            }(),
                      style: const TextStyle(
                          color: VetoPalette.textMuted, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: expiry ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (d != null) setDlg(() => expiry = d);
                    },
                    child: Text(_t(code, 'endDate')),
                  ),
                  TextButton(
                    onPressed: () => setDlg(() => expiry = null),
                    child: Text(_t(code, 'clearExpiry')),
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t(code, 'no'),
                  style: const TextStyle(color: VetoPalette.textMuted)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary),
              child: Text(_t(code, 'save')),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
      return;
    }

    final body = <String, dynamic>{
      'full_name': nameCtrl.text.trim(),
      'is_subscribed': subscribed,
      'manually_added': manual,
      'is_active': active,
    };
    final ph = phoneCtrl.text.trim();
    if (ph.isNotEmpty) body['phone'] = ph;
    final em = emailCtrl.text.trim();
    if (em.isNotEmpty) body['email'] = em;
    if (expiry != null) {
      body['subscription_expiry'] = expiry!.toUtc().toIso8601String();
    } else {
      body['subscription_expiry'] = null;
    }
    body.removeWhere((k, v) => v == null && k != 'subscription_expiry');

    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();

    await _putUser(uid, body, code);
  }

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: VetoPalette.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(msg,
              style: const TextStyle(color: VetoPalette.text, fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t(context.read<AppLanguageController>().code, 'no'),
                  style: const TextStyle(color: VetoPalette.textMuted)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: VetoPalette.primary),
              child: Text(_t(context.read<AppLanguageController>().code, 'yes')),
            ),
          ],
        ),
      ) == true;

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? VetoPalette.success : VetoPalette.emergency,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isRtl = AppLanguage.directionOf(code) == TextDirection.rtl;

    final activeCount = _subs.where((s) => s.status == 'active').length;
    final freeCount   = _subs.where((s) => s.status == 'free').length;
    final expiredCount= _subs.where((s) => s.status == 'expired').length;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoGlassTokens.bgBase,
        appBar: AppBar(
          backgroundColor: const Color(0x18FFFFFF),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: VetoGlassTokens.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_t(code, 'title'),
              style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded, color: VetoGlassTokens.textPrimary), onPressed: _load,
                tooltip: _t(code, 'refresh')),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: VetoGlassTokens.neonCyan,
            unselectedLabelColor: VetoGlassTokens.textMuted,
            indicatorColor: VetoGlassTokens.neonCyan,
            tabs: [
              Tab(text: _t(code, 'tabUsers'), icon: const Icon(Icons.people_rounded, size: 18)),
              Tab(text: _t(code, 'tabLogs'), icon: const Icon(Icons.history_rounded, size: 18)),
            ],
          ),
        ),
        body: VetoGlassAuroraBackground(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoGlassTokens.neonCyan))
            : _loadError != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: VetoPalette.emergency),
                      const SizedBox(height: 12),
                      Text(_loadError!,
                          style: const TextStyle(
                              color: VetoPalette.emergency, fontSize: 14),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('נסה שוב'),
                        style: FilledButton.styleFrom(
                            backgroundColor: VetoPalette.primary),
                      ),
                    ]),
                  ))
                : TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTab(code, activeCount, freeCount, expiredCount),
                  _buildLogsTab(code),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildUsersTab(String code, int activeCount, int freeCount, int expiredCount) {
    return Column(children: [
      // ── Summary bar ─────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Column(children: [
          Row(children: [
            _StatChip(icon: Icons.trending_up_rounded, color: VetoPalette.success,
                label: _t(code, 'monthly'), value: '\$${_monthlyRevenue.toStringAsFixed(0)}'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF5B8FFF),
                label: _t(code, 'allTime'), value: '\$${_totalRevenue.toStringAsFixed(0)}'),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _CountBadge(_t(code, 'total'), _subs.length, const Color(0xFF64748B)),
            const SizedBox(width: 8),
            _CountBadge(_t(code, 'active'), activeCount, VetoPalette.success),
            const SizedBox(width: 8),
            _CountBadge('Free', freeCount, const Color(0xFF5B8FFF)),
            const SizedBox(width: 8),
            _CountBadge(_t(code, 'expired'), expiredCount, VetoPalette.warning),
          ]),
        ]),
      ),
      // ── Search ──────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(
            hintText: _t(code, 'search'),
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
            filled: true, fillColor: VetoGlassTokens.glassFillStrong,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F8))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F8))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF5B8FFF), width: 1.5)),
          ),
        ),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F8)),
      Expanded(
        child: _filtered.isEmpty
            ? Center(child: Text(_t(code, 'noSubs'),
                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 15)))
            : ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final s = _filtered[i];
                  final uid = _userApiId(s);
                  return _SubCard(
                    sub: s,
                    code: code,
                    onActivate: () async {
                      if (await _confirm(_t(code, 'confirmActivate'))) {
                        await _putUser(uid, {
                          'is_subscribed': true,
                          'extendDays': 30,
                        }, code);
                      }
                    },
                    onCancel: () async {
                      if (await _confirm(_t(code, 'confirmCancel'))) {
                        await _putUser(uid, {'is_subscribed': false}, code);
                      }
                    },
                    onExtend: () async {
                      if (await _confirm(_t(code, 'confirmExtend'))) {
                        await _putUser(uid, {'extendDays': 30}, code);
                      }
                    },
                    onEdit: () => _openEditDialog(s, code),
                    onDelete: () async {
                      if (await _confirm(_t(code, 'confirmDeleteUser'))) {
                        await _deleteUserApi(uid, code);
                      }
                    },
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildLogsTab(String code) {
    if (_logs.isEmpty) {
      return Center(child: Text(_t(code, 'noLogs'),
          style: const TextStyle(color: VetoPalette.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _LogCard(log: _logs[i], code: code),
    );
  }
}

// ── Log card ─────────────────────────────────────────────────
class _LogCard extends StatelessWidget {
  final _LoginLog log;
  final String code;
  const _LogCard({required this.log, required this.code});

  @override
  Widget build(BuildContext context) {
    final color = log.success ? VetoPalette.success : VetoPalette.emergency;
    final ts = '${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year} '
        '${log.createdAt.hour.toString().padLeft(2,'0')}:${log.createdAt.minute.toString().padLeft(2,'0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Icon(log.success ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(log.eventLabel(code),
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 8),
            if (log.role != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: VetoPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(log.role!, style: const TextStyle(
                    color: VetoPalette.primary, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            const Spacer(),
            Text(ts, style: const TextStyle(color: VetoPalette.textMuted, fontSize: 11)),
          ]),
          if (log.phone != null || log.email != null) ...[
            const SizedBox(height: 2),
            Text(log.phone ?? log.email ?? '',
                style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 12),
                textDirection: TextDirection.ltr),
          ],
          if (log.errorMsg != null) ...[
            const SizedBox(height: 2),
            Text(log.errorMsg!,
                style: const TextStyle(color: VetoPalette.emergency, fontSize: 11)),
          ],
        ])),
      ]),
    );
  }
}

// ── Sub card ─────────────────────────────────────────────────
class _SubCard extends StatelessWidget {
  final _Sub sub;
  final String code;
  final VoidCallback onActivate, onCancel, onExtend, onEdit, onDelete;

  const _SubCard({
    required this.sub, required this.code,
    required this.onActivate, required this.onCancel, required this.onExtend,
    required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F8)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // User + status
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: VetoPalette.primary.withValues(alpha: 0.12),
            child: Text(sub.userName.isNotEmpty ? sub.userName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: VetoPalette.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sub.userName.isNotEmpty ? sub.userName : sub.userEmail,
                style: const TextStyle(
                    color: VetoPalette.text, fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Text(sub.userEmail,
                style: const TextStyle(
                    color: VetoPalette.textMuted, fontSize: 12)),
          ])),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sub.statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sub.statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(sub.statusLabel(code),
                style: TextStyle(
                    color: sub.statusColor, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        // Plan + dates + amount
        Wrap(spacing: 14, runSpacing: 4, children: [
          _InfoPill(Icons.card_membership_rounded, sub.planLabel(code),
              VetoPalette.accentSky),
          if (sub.amount > 0)
            _InfoPill(Icons.attach_money_rounded,
                '\$${sub.amount.toStringAsFixed(2)}', VetoPalette.success),
          if (sub.startDate != null)
            _InfoPill(Icons.calendar_today_outlined,
                '${sub.startDate!.day}/${sub.startDate!.month}/${sub.startDate!.year}',
                VetoPalette.textMuted),
          if (sub.endDate != null)
            _InfoPill(Icons.event_rounded,
                '→ ${sub.endDate!.day}/${sub.endDate!.month}/${sub.endDate!.year}',
                VetoPalette.warning),
        ]),
        const SizedBox(height: 10),
        // Action buttons
        Wrap(spacing: 8, runSpacing: 6, children: [
          _ActionBtn(
              label: _t(code, 'edit'),
              icon: Icons.edit_outlined,
              color: VetoPalette.info,
              onTap: onEdit),
          _ActionBtn(
              label: _t(code, 'delete'),
              icon: Icons.delete_outline_rounded,
              color: VetoPalette.emergency,
              onTap: onDelete),
          if (sub.status != 'active')
            _ActionBtn(
                label: _t(code, 'activate'),
                icon: Icons.check_circle_outline_rounded,
                color: VetoPalette.success,
                onTap: onActivate),
          if (sub.status == 'active')
            _ActionBtn(
                label: _t(code, 'cancel'),
                icon: Icons.cancel_outlined,
                color: VetoPalette.emergency,
                onTap: onCancel),
          _ActionBtn(
              label: _t(code, 'extend'),
              icon: Icons.add_circle_outline_rounded,
              color: VetoPalette.accentSky,
              onTap: onExtend),
        ]),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12,
          fontWeight: FontWeight.w600)),
    ]);
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _StatChip({required this.icon, required this.color,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.20))),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color,
            fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: VetoPalette.textMuted, fontSize: 11)),
      ]),
    ]),
  ));
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25))),
    child: Text('$label: $count',
        style: TextStyle(color: color, fontSize: 11,
            fontWeight: FontWeight.w600)),
  );
}
