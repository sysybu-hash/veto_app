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
    'title': 'ניהול מנויים',
    'revenue': 'הכנסות',
    'total': 'סה"כ מנויים',
    'active': 'פעילים',
    'expired': 'פגי תוקף',
    'cancelled': 'בוטלו',
    'monthly': 'הכנסה חודשית',
    'allTime': 'סה"כ הכנסות',
    'user': 'משתמש',
    'plan': 'תוכנית',
    'status': 'סטטוס',
    'startDate': 'התחלה',
    'endDate': 'פקיעה',
    'amount': 'סכום',
    'actions': 'פעולות',
    'activate': 'הפעל',
    'cancel': 'בטל',
    'extend': 'הארך 30 יום',
    'search': 'חיפוש לפי שם/מייל',
    'noSubs': 'אין מנויים',
    'loading': 'טוען...',
    'refresh': 'רענן',
    'statusActive': 'פעיל',
    'statusExpired': 'פג תוקף',
    'statusCancelled': 'בוטל',
    'statusTrial': 'ניסיון',
    'planFree': 'חינמי',
    'planBasic': 'בסיסי',
    'planPro': 'מקצועי',
    'confirmCancel': 'לבטל מנוי זה?',
    'confirmActivate': 'להפעיל מנוי זה?',
    'confirmExtend': 'להאריך ב-30 יום?',
    'yes': 'כן',
    'no': 'לא',
    'updated': 'המנוי עודכן',
  },
  'en': {
    'title': 'Subscription Management',
    'revenue': 'Revenue',
    'total': 'Total Subscriptions',
    'active': 'Active',
    'expired': 'Expired',
    'cancelled': 'Cancelled',
    'monthly': 'Monthly Revenue',
    'allTime': 'Total Revenue',
    'user': 'User',
    'plan': 'Plan',
    'status': 'Status',
    'startDate': 'Start',
    'endDate': 'Expires',
    'amount': 'Amount',
    'actions': 'Actions',
    'activate': 'Activate',
    'cancel': 'Cancel',
    'extend': 'Extend 30d',
    'search': 'Search by name/email',
    'noSubs': 'No subscriptions found',
    'loading': 'Loading...',
    'refresh': 'Refresh',
    'statusActive': 'Active',
    'statusExpired': 'Expired',
    'statusCancelled': 'Cancelled',
    'statusTrial': 'Trial',
    'planFree': 'Free',
    'planBasic': 'Basic',
    'planPro': 'Pro',
    'confirmCancel': 'Cancel this subscription?',
    'confirmActivate': 'Activate this subscription?',
    'confirmExtend': 'Extend by 30 days?',
    'yes': 'Yes',
    'no': 'No',
    'updated': 'Subscription updated',
  },
  'ru': {
    'title': 'Управление подписками',
    'revenue': 'Доход',
    'total': 'Всего подписок',
    'active': 'Активные',
    'expired': 'Истекшие',
    'cancelled': 'Отменённые',
    'monthly': 'Ежемесячный доход',
    'allTime': 'Общий доход',
    'user': 'Пользователь',
    'plan': 'Тарифный план',
    'status': 'Статус',
    'startDate': 'Начало',
    'endDate': 'Истекает',
    'amount': 'Сумма',
    'actions': 'Действия',
    'activate': 'Активировать',
    'cancel': 'Отменить',
    'extend': 'Продлить 30д',
    'search': 'Поиск по имени/email',
    'noSubs': 'Подписок не найдено',
    'loading': 'Загрузка...',
    'refresh': 'Обновить',
    'statusActive': 'Активна',
    'statusExpired': 'Истекла',
    'statusCancelled': 'Отменена',
    'statusTrial': 'Пробная',
    'planFree': 'Бесплатный',
    'planBasic': 'Базовый',
    'planPro': 'Pro',
    'confirmCancel': 'Отменить подписку?',
    'confirmActivate': 'Активировать подписку?',
    'confirmExtend': 'Продлить на 30 дней?',
    'yes': 'Да',
    'no': 'Нет',
    'updated': 'Подписка обновлена',
  },
};

String _t(String code, String key) =>
    (_i18n[code] ?? _i18n['en']!)[key] ?? key;

// ── Data model ────────────────────────────────────────────────
class _Sub {
  final String id, userId, userEmail, userName, plan, status;
  final double amount;
  final DateTime? startDate, endDate;

  const _Sub({
    required this.id, required this.userId, required this.userEmail,
    required this.userName, required this.plan, required this.status,
    required this.amount, this.startDate, this.endDate,
  });

  factory _Sub.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    return _Sub(
      id: j['_id'] ?? j['id'] ?? '',
      userId: user['_id'] ?? j['userId'] ?? '',
      userEmail: user['email'] ?? j['email'] ?? '',
      userName: user['name'] ?? j['userName'] ?? '',
      plan: j['plan'] ?? 'free',
      status: j['status'] ?? 'active',
      amount: ((j['amount'] ?? j['price'] ?? 0) as num).toDouble(),
      startDate: DateTime.tryParse(j['startDate'] ?? j['createdAt'] ?? ''),
      endDate: DateTime.tryParse(j['endDate'] ?? j['expiresAt'] ?? ''),
    );
  }

  Color get statusColor {
    switch (status) {
      case 'active': return VetoPalette.success;
      case 'trial': return const Color(0xFF0EA5E9);
      case 'expired': return VetoPalette.warning;
      case 'cancelled': return VetoPalette.emergency;
      default: return VetoPalette.textMuted;
    }
  }

  String statusLabel(String code) {
    switch (status) {
      case 'active': return _t(code, 'statusActive');
      case 'trial': return _t(code, 'statusTrial');
      case 'expired': return _t(code, 'statusExpired');
      case 'cancelled': return _t(code, 'statusCancelled');
      default: return status;
    }
  }

  String planLabel(String code) {
    switch (plan) {
      case 'free': return _t(code, 'planFree');
      case 'basic': return _t(code, 'planBasic');
      case 'pro': return _t(code, 'planPro');
      default: return plan;
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
    extends State<SubscriptionAdminScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<_Sub> _subs = [];
  List<_Sub> _filtered = [];
  bool _loading = true;

  double _monthlyRevenue = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
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
              s.userName.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final headers = AppConfig.httpHeaders({'Authorization': 'Bearer $tok'});
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/subscriptions'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['subscriptions'] ?? data['data'] ?? []);
        _subs = (list as List)
            .map((e) => _Sub.fromJson(e as Map<String, dynamic>))
            .toList();
        _filtered = _subs;
        // Compute revenue summaries
        _totalRevenue = _subs.fold(0, (s, x) => s + x.amount);
        final now = DateTime.now();
        _monthlyRevenue = _subs
            .where((s) =>
                s.status == 'active' &&
                (s.startDate?.month == now.month ||
                    s.startDate?.year == now.year))
            .fold(0, (s, x) => s + x.amount);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    _applyFilter();
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
    final expiredCount = _subs.where((s) => s.status == 'expired').length;
    final cancelledCount = _subs.where((s) => s.status == 'cancelled').length;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.darkBg,
          title: Text(_t(code, 'title'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: _t(code, 'refresh'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                // ── Summary bar ─────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: VetoPalette.surface,
                  child: Column(children: [
                    // Revenue row
                    Row(children: [
                      _StatChip(
                          icon: Icons.trending_up_rounded,
                          color: VetoPalette.success,
                          label: _t(code, 'monthly'),
                          value: '\$${_monthlyRevenue.toStringAsFixed(0)}'),
                      const SizedBox(width: 10),
                      _StatChip(
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF8B5CF6),
                          label: _t(code, 'allTime'),
                          value: '\$${_totalRevenue.toStringAsFixed(0)}'),
                    ]),
                    const SizedBox(height: 8),
                    // Status counts row
                    Row(children: [
                      _CountBadge(_t(code, 'total'), _subs.length,
                          VetoPalette.textMuted),
                      const SizedBox(width: 8),
                      _CountBadge(_t(code, 'active'), activeCount,
                          VetoPalette.success),
                      const SizedBox(width: 8),
                      _CountBadge(_t(code, 'expired'), expiredCount,
                          VetoPalette.warning),
                      const SizedBox(width: 8),
                      _CountBadge(_t(code, 'cancelled'), cancelledCount,
                          VetoPalette.emergency),
                    ]),
                  ]),
                ),
                // ── Search bar ──────────────────────────────
                Container(
                  color: VetoPalette.surface,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: VetoPalette.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _t(code, 'search'),
                      hintStyle: const TextStyle(color: VetoPalette.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: VetoPalette.textMuted, size: 20),
                      filled: true,
                      fillColor: VetoPalette.bg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: VetoPalette.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: VetoPalette.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: VetoPalette.primary, width: 1.5)),
                    ),
                  ),
                ),
                const Divider(height: 1, color: VetoPalette.border),
                // ── Subscription list ───────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(_t(code, 'noSubs'),
                              style: const TextStyle(
                                  color: VetoPalette.textMuted, fontSize: 15)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _SubCard(
                            sub: _filtered[i],
                            code: code,
                            onActivate: () async {
                              if (await _confirm(_t(code, 'confirmActivate'))) {
                                await _updateSub(_filtered[i].id,
                                    {'status': 'active'}, code);
                              }
                            },
                            onCancel: () async {
                              if (await _confirm(_t(code, 'confirmCancel'))) {
                                await _updateSub(_filtered[i].id,
                                    {'status': 'cancelled'}, code);
                              }
                            },
                            onExtend: () async {
                              if (await _confirm(_t(code, 'confirmExtend'))) {
                                await _updateSub(_filtered[i].id,
                                    {'extendDays': 30}, code);
                              }
                            },
                          ),
                        ),
                ),
              ]),
      ),
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
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
              const Color(0xFF8B5CF6)),
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
              color: const Color(0xFF0EA5E9),
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
