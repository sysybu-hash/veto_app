import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_2026.dart';
import '../../services/admin_service.dart';
import '_shell.dart';
import 'admin_i18n.dart';

String? _mongoEventId(dynamic ev) {
  final id = ev['_id'];
  if (id == null) return null;
  if (id is String) return id.isEmpty ? null : id;
  if (id is Map) {
    final o = id[r'$oid'] ?? id['oid'];
    if (o != null) return o.toString();
  }
  final t = id.toString();
  return (t.isEmpty || t == 'null') ? null : t;
}

class EmergencyLogsScreen extends StatefulWidget {
  const EmergencyLogsScreen({super.key});
  @override
  State<EmergencyLogsScreen> createState() => _EmergencyLogsScreenState();
}

class _EmergencyLogsScreenState extends State<EmergencyLogsScreen> {
  List<dynamic> _events = [];
  bool _loading = true;
  final _svc = AdminService();

  String _t(String code, String key) => AdminStrings.t(code, key);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getEmergencyLogs();
    if (mounted) setState(() { _events = data; _loading = false; });
  }

  Color _sc(String? s) {
    switch (s) {
      case 'completed':
      case 'resolved':
        return V26.ok;
      case 'cancelled':
        return V26.ink500;
      case 'failed':
        return V26.emerg;
      case 'accepted':
        return V26.ok;
      case 'in_progress':
      case 'pending':
        return V26.warn;
      case 'documentation':
        return V26.navy600;
      case 'dispatching':
      case 'active':
        return V26.emerg;
      default:
        return V26.ink500;
    }
  }

  String _sl(String? s) {
    final code = context.read<AppLanguageController>().code;
    return AdminStrings.eventStatus(code, s);
  }

  String _fmt(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2,"0")}:${d.minute.toString().padLeft(2,"0")}';
    } catch (_) { return iso; }
  }

  Future<void> _changeStatus(String id, String currentRaw) async {
    if (id.isEmpty) return;
    final code = context.read<AppLanguageController>().code;
    var initial = currentRaw;
    if (!AdminStrings.emergencyEventStatuses.contains(initial)) {
      initial = 'documentation';
    }
    var selected = initial;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(_t(code, 'changeStatus'), style: const TextStyle(color: V26.ink900)),
          content: StatefulBuilder(
            builder: (_, ss) => DropdownButton<String>(
              isExpanded: true,
              value: selected,
              dropdownColor: V26.surface,
              style: const TextStyle(color: V26.ink900, fontSize: 14),
              underline: Container(height: 1, color: V26.hairline),
              items: AdminStrings.emergencyEventStatuses
                  .map(
                    (v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(AdminStrings.eventStatus(code, v)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) ss(() => selected = v);
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t(code, 'cancel'),
                    style: const TextStyle(color: V26.ink500))),
            FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: V26.navy600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_t(code, 'save'))),
          ],
        ),
      ),
    );
    if (ok != true || selected == initial) return;
    final success = await _svc.updateEmergencyLog(id, {'status': selected});
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code == 'he'
                ? 'עדכון הסטטוס נכשל'
                : code == 'ru'
                    ? 'Не удалось обновить статус'
                    : 'Could not update status',
          ),
        ),
      );
    }
    _load();
  }

  Future<void> _confirmDelete(String id) async {
    if (id.isEmpty) return;
    final code = context.read<AppLanguageController>().code;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          backgroundColor: V26.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: V26.hairline),
          ),
          title: Text(_t(code, 'deleteEvent'), style: const TextStyle(color: V26.ink900)),
          content: Text(_t(code, 'deleteEventConfirm'),
              style: const TextStyle(color: V26.ink500)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t(code, 'cancel'),
                    style: const TextStyle(color: V26.ink500))),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: V26.emerg, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t(code, 'delete')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) { await _svc.deleteEmergencyLog(id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;

    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: AdminShell(
        active: AdminSection.logs,
        title: '${_t(code, 'emergencyLogs')} (${_loading ? _t(code, 'loading') : _events.length})',
        onRefresh: _load,
        body: V26Backdrop(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: V26.navy600))
            : _events.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_outline, color: V26.ok, size: 48),
                    const SizedBox(height: 12),
                    Text(_t(code, 'noEmergencyEvents'), style: const TextStyle(color: V26.ink500)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = _events[i];
                      final status = e['status']?.toString();
                      final eid = _mongoEventId(e) ?? '';
                      final user   = e['user_id'];
                      final lawyer = e['assigned_lawyer_id'];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: V26.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: _sc(status), width: 3),
                            top: const BorderSide(color: V26.hairline),
                            right: const BorderSide(color: V26.hairline),
                            bottom: const BorderSide(color: V26.hairline),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.warning_amber_rounded, color: _sc(status), size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              user != null
                                  ? (user['full_name'] ?? user['phone'] ?? _t(code, 'unknown'))
                                  : _t(code, 'unknown'),
                              style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w600),
                            )),
                            // Status badge — tap to change
                            GestureDetector(
                              onTap: eid.isEmpty ? null : () => _changeStatus(eid, status ?? ''),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _sc(status).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _sc(status).withValues(alpha: 0.4)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text(_sl(status), style: TextStyle(color: _sc(status), fontSize: 11)),
                                  const SizedBox(width: 3),
                                  Icon(Icons.edit, size: 10, color: _sc(status)),
                                ]),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: V26.emerg),
                              onPressed: eid.isEmpty ? null : () => _confirmDelete(eid),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(_fmt(e['triggered_at']?.toString()),
                              style: const TextStyle(color: V26.ink500, fontSize: 12)),
                          if (lawyer != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.gavel_rounded, color: V26.navy500, size: 14),
                              const SizedBox(width: 4),
                              Text('${_t(code, 'lawyerPrefix')}: ${lawyer['full_name'] ?? lawyer['phone'] ?? ""}',
                                  style: const TextStyle(color: V26.navy500, fontSize: 12)),
                            ]),
                          ],
                        ]),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
