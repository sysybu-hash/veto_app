// ============================================================
//  PendingLawyersScreen — VETO 2026
//  Tokens-aligned. Approve/reject lawyer applications.
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_tokens_2026.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_language_menu.dart';
import 'admin_i18n.dart';

class PendingLawyersScreen extends StatefulWidget {
  const PendingLawyersScreen({super.key});

  @override
  State<PendingLawyersScreen> createState() => _PendingLawyersScreenState();
}

class _PendingLawyersScreenState extends State<PendingLawyersScreen> {
  List<dynamic> _lawyers = [];
  bool _loading = true;
  final _svc = AdminService();

  String _t(String code, String key) => AdminStrings.t(code, key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getPendingLawyers();
    if (mounted) setState(() { _lawyers = data; _loading = false; });
  }

  Future<void> _approve(String id, String name) async {
    final code = context.read<AppLanguageController>().code;
    final ok = await _svc.approveLawyer(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '${_t(code, 'approveSuccess')}: $name' : _t(code, 'approveError')),
      backgroundColor: ok ? VetoTokens.ok : VetoTokens.emerg,
    ));
    if (ok) _load();
  }

  Future<void> _reject(String id, String name) async {
    final code = context.read<AppLanguageController>().code;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          title: Text(_t(code, 'rejectRequest'), style: VetoTokens.titleLg),
          content: Text('${_t(code, 'rejectRequestConfirm')}\n$name', style: VetoTokens.bodyMd),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t(code, 'cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: VetoTokens.emerg, foregroundColor: Colors.white),
              child: Text(_t(code, 'reject')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _svc.rejectLawyer(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '${_t(code, 'rejectSuccess')}: $name' : _t(code, 'rejectError')),
      backgroundColor: ok ? VetoTokens.ok : VetoTokens.emerg,
    ));
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_t(code, 'pendingLawyersTitle'), style: VetoTokens.titleLg),
          actions: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Center(child: AppLanguageMenu(compact: true))),
            IconButton(icon: const Icon(Icons.refresh_rounded, size: 18), onPressed: _load, tooltip: _t(code, 'refresh')),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
            : _lawyers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(color: VetoTokens.okSoft, borderRadius: BorderRadius.circular(20)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: VetoTokens.ok),
                        ),
                        const SizedBox(height: 16),
                        Text(_t(code, 'noPendingLawyers'), style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink500)),
                      ],
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _lawyers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final l = _lawyers[i];
                          final id = l['_id']?.toString() ?? '';
                          final name = (l['full_name'] ?? '—').toString();
                          final phone = (l['phone'] ?? '—').toString();
                          final email = (l['email'] ?? '').toString();
                          final license = (l['license_number'] ?? '—').toString();
                          final exp = (l['years_of_experience']?.toString() ?? '0');
                          final specs = (l['specializations'] as List?)?.join(', ') ?? '—';
                          return _PendingCard(
                            name: name, phone: phone, email: email,
                            license: license, exp: exp, specs: specs,
                            tCode: code, t: _t,
                            onApprove: () => _approve(id, name),
                            onReject: () => _reject(id, name),
                          );
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.name, required this.phone, required this.email,
    required this.license, required this.exp, required this.specs,
    required this.tCode, required this.t,
    required this.onApprove, required this.onReject,
  });
  final String name, phone, email, license, exp, specs, tCode;
  final String Function(String, String) t;
  final VoidCallback onApprove, onReject;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(VetoTokens.rMd),
        border: const Border(
          left: BorderSide(color: VetoTokens.warn, width: 3),
          top: BorderSide(color: VetoTokens.hairline),
          right: BorderSide(color: VetoTokens.hairline),
          bottom: BorderSide(color: VetoTokens.hairline),
        ),
        boxShadow: VetoTokens.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(gradient: VetoTokens.crestGradient, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Text(initial.isEmpty ? 'L' : initial, style: VetoTokens.serif(20, FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900)),
                  const SizedBox(height: 2),
                  Text('$phone${email.isNotEmpty ? ' · $email' : ''}', style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: VetoTokens.warnSoft, borderRadius: BorderRadius.circular(VetoTokens.rPill), border: Border.all(color: const Color(0xFFF2D58E))),
              child: Text(t(tCode, 'pending'), style: VetoTokens.sans(11, FontWeight.w800, color: const Color(0xFF7A5300))),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 14, runSpacing: 6, children: [
            _info(Icons.numbers_rounded, '${t(tCode, 'license')}: $license'),
            _info(Icons.work_outline_rounded, '${t(tCode, 'experienceYears')}: $exp'),
            _info(Icons.category_outlined, '${t(tCode, 'specializationsLabel')}: $specs'),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 14),
                label: Text(t(tCode, 'reject')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VetoTokens.emerg,
                  side: const BorderSide(color: Color(0xFFF4C7BD), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: VetoTokens.labelMd,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 14),
                label: Text(t(tCode, 'approve')),
                style: FilledButton.styleFrom(
                  backgroundColor: VetoTokens.ok,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VetoTokens.rSm)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: VetoTokens.labelMd,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: VetoTokens.ink500),
      const SizedBox(width: 5),
      Text(text, style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink700)),
    ]);
  }
}
