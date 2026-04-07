import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_theme.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_language_menu.dart';
import 'admin_i18n.dart';

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
      case 'active':   return VetoPalette.emergency;
      case 'resolved': return VetoPalette.success;
      case 'pending':  return VetoPalette.warning;
      default:         return VetoPalette.textMuted;
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

  Future<void> _changeStatus(String id, String current) async {
    final code = context.read<AppLanguageController>().code;
    String selected = current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: Text(_t(code, 'changeStatus'), style: const TextStyle(color: VetoPalette.text)),
          content: StatefulBuilder(builder: (_, ss) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ['active', 'pending', 'resolved'].map((s) => RadioListTile<String>(
              value: s,
              groupValue: selected,
              onChanged: (v) { if (v != null) ss(() => selected = v); },
              title: Text(_sl(s), style: TextStyle(color: _sc(s))),
            )).toList(),
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(code, 'cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_t(code, 'save'))),
          ],
        ),
      ),
    );
    if (ok == true && selected != current) {
      await _svc.updateEmergencyLog(id, {'status': selected});
      _load();
    }
  }

  Future<void> _confirmDelete(String id) async {
    final code = context.read<AppLanguageController>().code;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLanguage.directionOf(code),
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: Text(_t(code, 'deleteEvent'), style: const TextStyle(color: VetoPalette.text)),
          content: Text(_t(code, 'deleteEventConfirm'),
              style: const TextStyle(color: VetoPalette.textMuted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(code, 'cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
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
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.darkBg,
          title: Text('${_t(code, 'emergencyLogs')} (${_loading ? _t(code, 'loading') : _events.length})',
              style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: _t(code, 'refresh')),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _events.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_outline, color: VetoPalette.success, size: 48),
                    const SizedBox(height: 12),
                    Text(_t(code, 'noEmergencyEvents'), style: const TextStyle(color: VetoPalette.textMuted)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = _events[i];
                      final status = e['status']?.toString();
                      final eid    = e['_id']?.toString() ?? '';
                      final user   = e['user_id'];
                      final lawyer = e['assigned_lawyer_id'];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: VetoPalette.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: _sc(status), width: 3),
                            top: BorderSide(color: VetoPalette.border),
                            right: BorderSide(color: VetoPalette.border),
                            bottom: BorderSide(color: VetoPalette.border),
                          ),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.warning_amber_rounded, color: _sc(status), size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              user != null
                                  ? (user['full_name'] ?? user['phone'] ?? _t(code, 'unknown'))
                                  : _t(code, 'unknown'),
                              style: const TextStyle(color: VetoPalette.text, fontWeight: FontWeight.w600),
                            )),
                            // Status badge — tap to change
                            GestureDetector(
                              onTap: () => _changeStatus(eid, status ?? ''),
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
                              icon: const Icon(Icons.delete_outline, size: 20, color: VetoPalette.emergency),
                              onPressed: () => _confirmDelete(eid),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(_fmt(e['triggered_at']?.toString()),
                              style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
                          if (lawyer != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.gavel_rounded, color: VetoPalette.primary, size: 14),
                              const SizedBox(width: 4),
                              Text('${_t(code, 'lawyerPrefix')}: ${lawyer['full_name'] ?? lawyer['phone'] ?? ""}',
                                  style: const TextStyle(color: VetoPalette.primary, fontSize: 12)),
                            ]),
                          ],
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}
