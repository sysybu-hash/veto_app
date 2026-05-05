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
import '../core/theme/veto_2026.dart';
import '../services/auth_service.dart';
import 'admin/_shell.dart';
import '../l10n/app_localizations.dart';
import 'admin/admin_l10n_lookups.dart';

String _sub(BuildContext context, String key) =>
    subAdmT(AppLocalizations.of(context)!, key);

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
      case 'active': return V26.ok;
      case 'free': return V26.navy500;
      case 'trial': return V26.navy500;
      case 'expired': return V26.warn;
      case 'cancelled': return V26.emerg;
      case 'no_subscription': return V26.ink500;
      case 'unverified': return V26.ink500;
      default: return V26.ink500;
    }
  }

  String statusLabel(BuildContext context) {
    switch (status) {
      case 'active': return _sub(context, 'statusActive');
      case 'free': return _sub(context, 'statusFree');
      case 'trial': return _sub(context, 'statusTrial');
      case 'expired': return _sub(context, 'statusExpired');
      case 'cancelled': return _sub(context, 'statusCancelled');
      case 'no_subscription': return _sub(context, 'statusNoSub');
      case 'unverified': return _sub(context, 'statusUnverified');
      default: return status;
    }
  }

  String planLabel(BuildContext context) {
    switch (plan) {
      case 'free': return _sub(context, 'planFree');
      case 'basic': return _sub(context, 'planBasic');
      case 'pro': return _sub(context, 'planPro');
      case 'none': return _sub(context, 'planNone');
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

  String eventLabel(BuildContext context) {
    switch (event) {
      case 'register':     return _sub(context, 'logRegister');
      case 'otp_request':  return _sub(context, 'logOtpReq');
      case 'otp_success':  return _sub(context, 'logOtpOk');
      case 'otp_fail':     return _sub(context, 'logOtpFail');
      case 'google_login': return _sub(context, 'logGoogle');
      case 'google_fail':  return _sub(context, 'logGoogleFail');
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
  int _renewalsThisMonth = 0;
  double _arpu = 0;
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
        _totalRevenue = _subs.where((s) => s.amount > 0).fold(0.0, (s, x) => s + x.amount);
        _monthlyRevenue = _subs
            .where((s) =>
                s.status == 'active' &&
                s.startDate != null &&
                s.startDate!.month == now.month &&
                s.startDate!.year == now.year)
            .fold(0.0, (s, x) => s + x.amount);
        _renewalsThisMonth = _subs
            .where((s) =>
                s.status == 'active' &&
                s.startDate != null &&
                s.startDate!.month == now.month &&
                s.startDate!.year == now.year)
            .length;
        final activePaying = _subs.where((s) => s.status == 'active').length;
        _arpu = activePaying > 0 ? _monthlyRevenue / activePaying : 0;
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

  Future<void> _putUser(String userId, Map<String, dynamic> body) async {
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
        if (!mounted) return;
        _snack(_sub(context, 'updated'));
        await _load();
      } else {
        if (!mounted) return;
        _snack('${_sub(context, 'errorSave')}: ${res.statusCode}', ok: false);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('${_sub(context, 'errorSave')}: $e', ok: false);
    }
  }

  Future<void> _deleteUserApi(String userId) async {
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
        if (!mounted) return;
        _snack(_sub(context, 'deleted'));
        await _load();
      } else {
        if (!mounted) return;
        _snack('${_sub(context, 'errorSave')}: ${res.statusCode}', ok: false);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('${_sub(context, 'errorSave')}: $e', ok: false);
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
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(_sub(context, 'edit'),
              style: const TextStyle(
                  color: V26.ink900, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  cursorColor: V26.navy600,
                  decoration: InputDecoration(
                    labelText: _sub(context, 'fullName'),
                    labelStyle: const TextStyle(color: V26.ink500),
                    filled: true,
                    fillColor: const Color(0xFF0F1A24),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: V26.hairline)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: V26.hairline)),
                  ),
                  style: const TextStyle(color: V26.ink900),
                ),
                TextField(
                  controller: phoneCtrl,
                  cursorColor: V26.navy600,
                  decoration: InputDecoration(
                    labelText: _sub(context, 'phoneLabel'),
                    labelStyle: const TextStyle(color: V26.ink500),
                    filled: true,
                    fillColor: const Color(0xFF0F1A24),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: V26.hairline)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: V26.hairline)),
                  ),
                  style: const TextStyle(color: V26.ink900),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailCtrl,
                  cursorColor: V26.navy600,
                  decoration: InputDecoration(
                    labelText: _sub(context, 'emailLabel'),
                    labelStyle: const TextStyle(color: V26.ink500),
                    filled: true,
                    fillColor: const Color(0xFF0F1A24),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: V26.hairline)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: V26.hairline)),
                  ),
                  style: const TextStyle(color: V26.ink900),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_sub(context, 'subscribed'),
                      style: const TextStyle(color: V26.ink900, fontSize: 14)),
                  trailing: Switch(
                    value: subscribed,
                    onChanged: (v) => setDlg(() => subscribed = v),
                    activeTrackColor: V26.navy600.withValues(alpha: 0.4),
                    activeThumbColor: V26.navy600,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_sub(context, 'manualExempt'),
                      style: const TextStyle(color: V26.ink900, fontSize: 14)),
                  trailing: Switch(
                    value: manual,
                    onChanged: (v) => setDlg(() => manual = v),
                    activeTrackColor: V26.navy600.withValues(alpha: 0.4),
                    activeThumbColor: V26.navy600,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_sub(context, 'accountEnabled'),
                      style: const TextStyle(color: V26.ink900, fontSize: 14)),
                  trailing: Switch(
                    value: active,
                    onChanged: (v) => setDlg(() => active = v),
                    activeTrackColor: V26.navy600.withValues(alpha: 0.4),
                    activeThumbColor: V26.navy600,
                  ),
                ),
                Row(children: [
                  Expanded(
                    child: Text(
                      expiry == null
                          ? _sub(context, 'subscriptionExpiry')
                          : () {
                              final x = expiry!;
                              return '${_sub(context, 'subscriptionExpiry')}: '
                                  '${x.day}/${x.month}/${x.year}';
                            }(),
                      style: const TextStyle(
                          color: V26.ink500, fontSize: 13),
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
                    child: Text(_sub(context, 'endDate')),
                  ),
                  TextButton(
                    onPressed: () => setDlg(() => expiry = null),
                    child: Text(_sub(context, 'clearExpiry')),
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_sub(context, 'no'),
                  style: const TextStyle(color: V26.ink500)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: V26.navy600,
                foregroundColor: Colors.white,
              ),
              child: Text(_sub(context, 'save')),
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

    await _putUser(uid, body);
  }

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline),
          ),
          content: Text(msg,
              style: const TextStyle(color: V26.ink900, fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_sub(context, 'no'),
                  style: const TextStyle(color: V26.ink500)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: V26.navy600,
                foregroundColor: Colors.white,
              ),
              child: Text(_sub(context, 'yes')),
            ),
          ],
        ),
      ) == true;

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? V26.ok : V26.emerg,
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
      child: AdminShell(
        active: AdminSection.subscriptions,
        title: _sub(context, 'title'),
        onRefresh: _load,
        bottom: TabBar(
          controller: _tabController,
          labelColor: V26.navy600,
          unselectedLabelColor: V26.ink500,
          indicatorColor: V26.navy600,
          tabs: [
            Tab(text: _sub(context, 'tabUsers'), icon: const Icon(Icons.people_rounded, size: 18)),
            Tab(text: _sub(context, 'tabLogs'), icon: const Icon(Icons.history_rounded, size: 18)),
          ],
        ),
        body: V26Backdrop(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: V26.navy600))
            : _loadError != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: V26.emerg),
                      const SizedBox(height: 12),
                      Text(_loadError!,
                          style: const TextStyle(
                              color: V26.emerg, fontSize: 14),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(_sub(context, 'retry')),
                        style: FilledButton.styleFrom(
                            backgroundColor: V26.navy600),
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
      // ── Summary: MRR + 3 KPIs + plan list (₪) ─────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [V26.navy900, V26.navy900.withValues(alpha: 0.88)],
          ),
          border: const Border(
            bottom: BorderSide(color: V26.hairline),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                V26Badge(_sub(context, 'mrrBadge'), tone: V26BadgeTone.gold),
                const SizedBox(width: 10),
                Text(
                  '₪${_monthlyRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                V26PillCTA(
                  label: _sub(context, 'newPlan'),
                  icon: Icons.add_rounded,
                  onTap: () => _snack(_sub(context, 'newPlanHint')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.verified_user_outlined,
                    color: V26.ok,
                    label: _sub(context, 'active'),
                    value: '$activeCount',
                    onDark: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    icon: Icons.autorenew_rounded,
                    color: V26.goldDeep,
                    label: _sub(context, 'renewalsThisMonth'),
                    value: '$_renewalsThisMonth',
                    onDark: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    icon: Icons.analytics_outlined,
                    color: V26.navy500,
                    label: _sub(context, 'arpu'),
                    value: '₪${_arpu.toStringAsFixed(0)}',
                    onDark: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _sub(context, 'plansTitle'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PlanPriceCell(
                    label: _sub(context, 'premiumMonthly'),
                    price: '₪99',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanPriceCell(
                    label: _sub(context, 'premiumYearly'),
                    price: '₪899',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanPriceCell(
                    label: _sub(context, 'freeTier'),
                    price: '₪0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.account_balance_wallet_rounded,
                    color: V26.navy500,
                    label: _sub(context, 'allTime'),
                    value: '₪${_totalRevenue.toStringAsFixed(0)}',
                    onDark: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    icon: Icons.groups_outlined,
                    color: V26.ink500,
                    label: _sub(context, 'total'),
                    value: '${_subs.length}',
                    onDark: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CountBadge(_sub(context, 'active'), activeCount, V26.ok),
                _CountBadge(_sub(context, 'statusFree'), freeCount, V26.navy500),
                _CountBadge(_sub(context, 'expired'), expiredCount, V26.warn),
              ],
            ),
          ],
        ),
      ),
      // ── Search ──────────────────────────────────────────────
      Container(
        color: V26.surface,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: V26.ink900, fontSize: 14),
          cursorColor: V26.navy600,
          decoration: InputDecoration(
            hintText: _sub(context, 'search'),
            hintStyle: const TextStyle(color: V26.ink500),
            prefixIcon: const Icon(Icons.search_rounded, color: V26.ink500, size: 20),
            filled: true,
            fillColor: const Color(0xFF0F1A24),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: V26.hairline)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: V26.navy600, width: 1.5)),
          ),
        ),
      ),
      const Divider(height: 1, color: V26.hairline),
      Expanded(
        child: _filtered.isEmpty
            ? Center(child: Text(_sub(context, 'noSubs'),
                style: const TextStyle(color: V26.ink500, fontSize: 15)))
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
                      if (await _confirm(_sub(context, 'confirmActivate'))) {
                        await _putUser(uid, {
                          'is_subscribed': true,
                          'extendDays': 30,
                        });
                      }
                    },
                    onCancel: () async {
                      if (await _confirm(_sub(context, 'confirmCancel'))) {
                        await _putUser(uid, {'is_subscribed': false});
                      }
                    },
                    onExtend: () async {
                      if (await _confirm(_sub(context, 'confirmExtend'))) {
                        await _putUser(uid, {'extendDays': 30});
                      }
                    },
                    onEdit: () => _openEditDialog(s, code),
                    onDelete: () async {
                      if (await _confirm(_sub(context, 'confirmDeleteUser'))) {
                        await _deleteUserApi(uid);
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
      return Center(child: Text(_sub(context, 'noLogs'),
          style: const TextStyle(color: V26.ink500)));
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
    final color = log.success ? V26.ok : V26.emerg;
    final ts = '${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year} '
        '${log.createdAt.hour.toString().padLeft(2,'0')}:${log.createdAt.minute.toString().padLeft(2,'0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: V26.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: V26.hairline),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Icon(log.success ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(log.eventLabel(context),
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 8),
            if (log.role != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: V26.navy600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(log.role!, style: const TextStyle(
                    color: V26.navy600, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            const Spacer(),
            Text(ts, style: const TextStyle(color: V26.ink500, fontSize: 11)),
          ]),
          if (log.phone != null || log.email != null) ...[
            const SizedBox(height: 2),
            Text(log.phone ?? log.email ?? '',
                style: const TextStyle(color: V26.ink300, fontSize: 12),
                textDirection: TextDirection.ltr),
          ],
          if (log.errorMsg != null) ...[
            const SizedBox(height: 2),
            Text(log.errorMsg!,
                style: const TextStyle(color: V26.emerg, fontSize: 11)),
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
        color: V26.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: V26.hairline),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // User + status
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: V26.navy600.withValues(alpha: 0.12),
            child: Text(sub.userName.isNotEmpty ? sub.userName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: V26.navy600, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sub.userName.isNotEmpty ? sub.userName : sub.userEmail,
                style: const TextStyle(
                    color: V26.ink900, fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Text(sub.userEmail,
                style: const TextStyle(
                    color: V26.ink500, fontSize: 12)),
          ])),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sub.statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sub.statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(sub.statusLabel(context),
                style: TextStyle(
                    color: sub.statusColor, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        // Plan + dates + amount
        Wrap(spacing: 14, runSpacing: 4, children: [
          _InfoPill(Icons.card_membership_rounded, sub.planLabel(context),
              V26.navy500),
          if (sub.amount > 0)
            _InfoPill(Icons.payments_rounded,
                '₪${sub.amount.toStringAsFixed(2)}', V26.ok),
          if (sub.startDate != null)
            _InfoPill(Icons.calendar_today_outlined,
                '${sub.startDate!.day}/${sub.startDate!.month}/${sub.startDate!.year}',
                V26.ink500),
          if (sub.endDate != null)
            _InfoPill(Icons.event_rounded,
                '→ ${sub.endDate!.day}/${sub.endDate!.month}/${sub.endDate!.year}',
                V26.warn),
        ]),
        const SizedBox(height: 10),
        // Action buttons
        Wrap(spacing: 8, runSpacing: 6, children: [
          _ActionBtn(
              label: _sub(context, 'edit'),
              icon: Icons.edit_outlined,
              color: V26.navy600,
              onTap: onEdit),
          _ActionBtn(
              label: _sub(context, 'delete'),
              icon: Icons.delete_outline_rounded,
              color: V26.emerg,
              onTap: onDelete),
          if (sub.status != 'active')
            _ActionBtn(
                label: _sub(context, 'activate'),
                icon: Icons.check_circle_outline_rounded,
                color: V26.ok,
                onTap: onActivate),
          if (sub.status == 'active')
            _ActionBtn(
                label: _sub(context, 'cancel'),
                icon: Icons.cancel_outlined,
                color: V26.emerg,
                onTap: onCancel),
          _ActionBtn(
              label: _sub(context, 'extend'),
              icon: Icons.add_circle_outline_rounded,
              color: V26.navy500,
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
  final bool onDark;
  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = onDark
        ? Colors.white.withValues(alpha: 0.65)
        : V26.ink500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: onDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: onDark ? 0.35 : 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(color: labelColor, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPriceCell extends StatelessWidget {
  final String label;
  final String price;
  const _PlanPriceCell({required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            price,
            style: const TextStyle(
              color: V26.goldDeep,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
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
