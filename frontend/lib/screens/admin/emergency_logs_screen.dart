// ============================================================
//  EmergencyLogsScreen — VETO 2026
//  Tokens-aligned. View / change status / delete emergency events.
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_tokens_2026.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_language_menu.dart';
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getEmergencyLogs();
    if (mounted) setState(() { _events = data; _loading = false; });
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'completed':
      case 'resolved':
      case 'accepted':
        return VetoTokens.ok;
      case 'cancelled':
        return VetoTokens.ink300;
      case 'failed':
      case 'dispatching':
      case 'active':
        return VetoTokens.emerg;
      case 'in_progress':
      case 'pending':
        return VetoTokens.warn;
      case 'documentation':
        return VetoTokens.navy600;
      default:
        return VetoTokens.ink300;
    }
  }

  String _statusLabel(String? s) {
    final code = context.read<AppLanguageController>().code;
    return AdminStrings.eventStatus(code, s);
  }

  String _fmt(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
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
          title: Text(_t(code, 'changeStatus'), style: VetoTokens.titleLg),
          content: SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (_, ss) => DropdownButton<String>(
                isExpanded: true,
                value: selected,
                style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink900),
                underline: Container(height: 1, color: VetoTokens.hairline),
                items: AdminStrings.emergencyEventStatuses
                    .map((v) => DropdownMenuItem<String>(value: v, child: Text(AdminStrings.eventStatus(code, v))))
                    .toList(),
                onChanged: (v) { if (v != null) ss(() => selected = v); },
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoTokens.navy600, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t(code, 'save')),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected == initial) return;
    final success = await _svc.updateEmergencyLog(id, {'status': selected});
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(code == 'he' ? 'עדכון הסטטוס נכשל' : code == 'ru' ? 'Не удалось обновить статус' : 'Could not update status'),
        backgroundColor: VetoTokens.emerg,
      ));
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
          title: Text(_t(code, 'deleteEvent'), style: VetoTokens.titleLg),
          content: Text(_t(code, 'deleteEventConfirm'), style: VetoTokens.bodyMd),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoTokens.emerg, foregroundColor: Colors.white),
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
      child: Scaffold(
        backgroundColor: VetoTokens.paper,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            '${_t(code, 'emergencyLogs')} (${_loading ? _t(code, 'loading') : _events.length})',
            style: VetoTokens.titleLg,
          ),
          actions: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Center(child: AppLanguageMenu(compact: true))),
            IconButton(icon: const Icon(Icons.refresh_rounded, size: 18), onPressed: _load, tooltip: _t(code, 'refresh')),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
            : _events.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(color: VetoTokens.okSoft, borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: VetoTokens.ok),
                      ),
                      const SizedBox(height: 16),
                      Text(_t(code, 'noEmergencyEvents'), style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink500)),
                    ]),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = _events[i];
                          final status = e['status']?.toString();
                          final eid = _mongoEventId(e) ?? '';
                          final user = e['user_id'];
                          final lawyer = e['assigned_lawyer_id'];
                          final color = _statusColor(status);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(VetoTokens.rMd),
                              border: Border(
                                left: BorderSide(color: color, width: 3),
                                top: const BorderSide(color: VetoTokens.hairline),
                                right: const BorderSide(color: VetoTokens.hairline),
                                bottom: const BorderSide(color: VetoTokens.hairline),
                              ),
                              boxShadow: VetoTokens.shadow1,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.warning_amber_rounded, color: color, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user != null
                                          ? (user['full_name'] ?? user['phone'] ?? _t(code, 'unknown')).toString()
                                          : _t(code, 'unknown'),
                                      style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink900),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: eid.isEmpty ? null : () => _changeStatus(eid, status ?? ''),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(VetoTokens.rPill),
                                        border: Border.all(color: color.withValues(alpha: 0.36), width: 1),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Text(_statusLabel(status), style: VetoTokens.sans(11, FontWeight.w800, color: color)),
                                        const SizedBox(width: 3),
                                        Icon(Icons.edit, size: 10, color: color),
                                      ]),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: VetoTokens.emerg),
                                    onPressed: eid.isEmpty ? null : () => _confirmDelete(eid),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Text(_fmt(e['triggered_at']?.toString()), style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                                if (lawyer != null) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.gavel_rounded, color: VetoTokens.navy500, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_t(code, 'lawyerPrefix')}: ${lawyer['full_name'] ?? lawyer['phone'] ?? ""}',
                                      style: VetoTokens.bodyXs.copyWith(color: VetoTokens.navy600, fontWeight: FontWeight.w600),
                                    ),
                                  ]),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}
