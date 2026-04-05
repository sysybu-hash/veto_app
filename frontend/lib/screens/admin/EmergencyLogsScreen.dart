import 'package:flutter/material.dart';
import '../../core/theme/veto_theme.dart';
import '../../services/admin_service.dart';

class EmergencyLogsScreen extends StatefulWidget {
  const EmergencyLogsScreen({super.key});
  @override
  State<EmergencyLogsScreen> createState() => _EmergencyLogsScreenState();
}

class _EmergencyLogsScreenState extends State<EmergencyLogsScreen> {
  List<dynamic> _events = [];
  bool _loading = true;
  final _svc = AdminService();

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
    switch (s) {
      case 'active':   return 'פעיל';
      case 'resolved': return 'סגור';
      case 'pending':  return 'ממתין';
      default:         return s ?? 'לא ידוע';
    }
  }

  String _fmt(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2,"0")}:${d.minute.toString().padLeft(2,"0")}';
    } catch (_) { return iso; }
  }

  Future<void> _changeStatus(String id, String current) async {
    String selected = current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: const Text('שנה סטטוס', style: TextStyle(color: VetoPalette.text)),
          content: StatefulBuilder(builder: (_, ss) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ['active', 'pending', 'resolved'].map((s) => RadioListTile<String>(
              value: s,
              groupValue: selected,
              onChanged: (v) => ss(() => selected = v!),
              title: Text(_sl(s), style: TextStyle(color: _sc(s))),
            )).toList(),
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('שמור')),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: VetoPalette.surface,
          title: const Text('מחק אירוע', style: TextStyle(color: VetoPalette.text)),
          content: const Text('האם למחוק את רשומת האירוע לצמיתות?',
              style: TextStyle(color: VetoPalette.textMuted)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: VetoPalette.emergency),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) { await _svc.deleteEmergencyLog(id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        appBar: AppBar(
          backgroundColor: VetoPalette.surface,
          title: Text('יומני חירום (${_loading ? "..." : _events.length})',
              style: const TextStyle(color: VetoPalette.text)),
          iconTheme: const IconThemeData(color: VetoPalette.text),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _events.isEmpty
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline, color: VetoPalette.success, size: 48),
                    SizedBox(height: 12),
                    Text('אין אירועי חירום', style: TextStyle(color: VetoPalette.textMuted)),
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
                          border: Border.all(color: VetoPalette.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.warning_amber_rounded, color: _sc(status), size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              user != null
                                  ? (user['full_name'] ?? user['phone'] ?? 'לא ידוע')
                                  : 'לא ידוע',
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
                              Text('עו"ד: ${lawyer['full_name'] ?? lawyer['phone'] ?? ""}',
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
