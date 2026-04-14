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
    'yes': 'כן',
    'no': 'לא',
    'updated': 'עודכן',
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
    'yes': 'Yes',
    'no': 'No',
    'updated': 'Updated',
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
    'yes': 'Да',
    'no': 'Нет',
    'updated': 'Обновлено',
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

  const _Sub({
    required this.id, required this.userId, required this.userEmail,
    required this.userName, required this.phone, required this.plan,
    required this.status, required this.amount,
    this.startDate, this.endDate,
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
    );
  }

  Color get statusColor {
    switch (status) {
      case 'active': return VetoPalette.success;
      case 'free': return const Color(0xFFC9A050);
      case 'trial': return const Color(0xFFC9A050);
      case 'expired': return VetoPalette.warning;
      case 'cancelled': return VetoPalette.emergency;
      case 'no_subscription': return VetoPalette.textMuted;
      case 'unverified': return const Color(0xFF7A7260);
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

  Future<void> _updateSub(String id, Map<String, dynamic> body,
      String code) async {
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final res = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/admin/subscriptions/$id'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _snack(_t(code, 'updated'));
        await _load();
      }
    } catch (_) {}
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: VetoPalette.success,
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
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.darkBg,
          title: Text(_t(code, 'title'),
              style: const TextStyle(color: VetoColors.white, fontWeight: FontWeight.w700)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load,
                tooltip: _t(code, 'refresh')),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: VetoPalette.primary,
            tabs: [
              Tab(text: _t(code, 'tabUsers'), icon: const Icon(Icons.people_rounded, size: 18)),
              Tab(text: _t(code, 'tabLogs'), icon: const Icon(Icons.history_rounded, size: 18)),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
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
    );
  }

  Widget _buildUsersTab(String code, int activeCount, int freeCount, int expiredCount) {
    return Column(children: [
      // ── Summary bar ─────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: VetoPalette.surface,
        child: Column(children: [
          Row(children: [
            _StatChip(icon: Icons.trending_up_rounded, color: VetoPalette.success,
                label: _t(code, 'monthly'), value: '\$${_monthlyRevenue.toStringAsFixed(0)}'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFC9A050),
                label: _t(code, 'allTime'), value: '\$${_totalRevenue.toStringAsFixed(0)}'),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _CountBadge(_t(code, 'total'), _subs.length, VetoPalette.textMuted),
            const SizedBox(width: 8),
            _CountBadge(_t(code, 'active'), activeCount, VetoPalette.success),
            const SizedBox(width: 8),
            _CountBadge('Free', freeCount, const Color(0xFFC9A050)),
            const SizedBox(width: 8),
            _CountBadge(_t(code, 'expired'), expiredCount, VetoPalette.warning),
          ]),
        ]),
      ),
      // ── Search ──────────────────────────────────────────────
      Container(
        color: VetoPalette.surface,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: VetoPalette.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: _t(code, 'search'),
            hintStyle: const TextStyle(color: VetoPalette.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: VetoPalette.textMuted, size: 20),
            filled: true, fillColor: VetoPalette.bg,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoPalette.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoPalette.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetoPalette.primary, width: 1.5)),
          ),
        ),
      ),
      const Divider(height: 1, color: VetoPalette.border),
      Expanded(
        child: _filtered.isEmpty
            ? Center(child: Text(_t(code, 'noSubs'),
                style: const TextStyle(color: VetoPalette.textMuted, fontSize: 15)))
            : ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _SubCard(
                  sub: _filtered[i], code: code,
                  onActivate: () async {
                    if (await _confirm(_t(code, 'confirmActivate'))) {
                      await _updateSub(_filtered[i].id, {'status': 'active'}, code);
                    }
                  },
                  onCancel: () async {
                    if (await _confirm(_t(code, 'confirmCancel'))) {
                      await _updateSub(_filtered[i].id, {'status': 'cancelled'}, code);
                    }
                  },
                  onExtend: () async {
                    if (await _confirm(_t(code, 'confirmExtend'))) {
                      await _updateSub(_filtered[i].id, {'extendDays': 30}, code);
                    }
                  },
                ),
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
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
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
                  color: VetoPalette.primary.withOpacity(0.1),
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
  final VoidCallback onActivate, onCancel, onExtend;

  const _SubCard({
    required this.sub, required this.code,
    required this.onActivate, required this.onCancel, required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VetoPalette.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // User + status
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: VetoPalette.primary.withOpacity(0.12),
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
              color: sub.statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sub.statusColor.withOpacity(0.3)),
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
              const Color(0xFFC9A050)),
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
        Wrap(spacing: 8, children: [
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
              color: const Color(0xFFC9A050),
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
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25))),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.20))),
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Text('$label: $count',
        style: TextStyle(color: color, fontSize: 11,
            fontWeight: FontWeight.w600)),
  );
}
