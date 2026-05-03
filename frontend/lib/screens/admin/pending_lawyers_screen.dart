import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_2026.dart';
import '../../services/admin_service.dart';
import '_shell.dart';
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
      backgroundColor: ok ? V26.ok : V26.emerg,
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
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(_t(code, 'rejectRequest'), style: const TextStyle(color: V26.ink900)),
          content: Text('${_t(code, 'rejectRequestConfirm')}\n$name',
              style: const TextStyle(color: V26.ink500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_t(code, 'cancel'), style: const TextStyle(color: V26.ink500)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_t(code, 'reject'), style: const TextStyle(color: V26.emerg)),
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
      backgroundColor: ok ? V26.ok : V26.emerg,
    ));
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: AdminShell(
        active: AdminSection.pending,
        title: _t(code, 'pendingLawyersTitle'),
        onRefresh: _load,
        body: V26Backdrop(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: V26.navy600))
            : _lawyers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 64, color: V26.ok),
                        const SizedBox(height: 16),
                        Text(
                          _t(code, 'noPendingLawyers'),
                          style: const TextStyle(color: V26.ink500, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lawyers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final l = _lawyers[i];
                      final id = l['_id']?.toString() ?? '';
                      final name = l['full_name'] ?? '\u2014';
                      final phone = l['phone'] ?? '\u2014';
                      final email = l['email'] ?? '';
                        final license = l['license_number'] ?? '�';
                      final exp = l['years_of_experience']?.toString() ?? '0';
                      final specs =
                          (l['specializations'] as List?)?.join(', ') ?? '�';

                      return Container(
                        decoration: BoxDecoration(
                          color: V26.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(color: V26.warn, width: 3),
                            top: BorderSide(color: V26.hairline),
                            right: BorderSide(color: V26.hairline),
                            bottom: BorderSide(color: V26.hairline),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.gavel_rounded,
                                  color: V26.navy600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: V26.ink900,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            _info(Icons.phone_iphone_rounded, phone),
                            if (email.isNotEmpty) _info(Icons.email_outlined, email),
                            _info(Icons.numbers_rounded, '${_t(code, 'license')}: $license'),
                            _info(Icons.work_outline_rounded,
                                '${_t(code, 'experienceYears')}: $exp'),
                            _info(Icons.category_outlined,
                                '${_t(code, 'specializationsLabel')}: $specs'),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _reject(id, name),
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  label: Text(_t(code, 'reject')),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: V26.emerg,
                                    side: const BorderSide(color: V26.emerg),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approve(id, name),
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: Text(_t(code, 'approve')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: V26.ok,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(icon, size: 14, color: V26.ink500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: V26.ink500, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}
