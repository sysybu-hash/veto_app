import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_glass_system.dart';
import '../../core/theme/veto_theme.dart';
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
        return VetoPalette.success;
      case 'cancelled':
        return VetoPalette.textMuted;
      case 'failed':
        return VetoPalette.emergency;
      case 'accepted':
        return VetoPalette.success;
      case 'in_progress':
      case 'pending':
        return VetoPalette.warning;
      case 'documentation':
        return VetoPalette.primary;
      case 'dispatching':
      case 'active':
        return VetoPalette.emergency;
      default:
        return VetoPalette.textMuted;
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
          backgroundColor: VetoGlassTokens.sheetPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: VetoGlassTokens.glassBorder),
          ),
          title: Text(_t(code, 'changeStatus'), style: const TextStyle(color: VetoGlassTokens.textPrimary)),
          content: StatefulBuilder(
            builder: (_, ss) => DropdownButton<String>(
              isExpanded: true,
              value: selected,
              dropdownColor: VetoGlassTokens.menuPanel,
              style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 14),
              underline: Container(height: 1, color: VetoGlassTokens.glassBorder),
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
                    style: const TextStyle(color: VetoGlassTokens.textMuted))),
            FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: VetoGlassTokens.neonCyan,
                  foregroundColor: VetoGlassTokens.onNeon,
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
          backgroundColor: VetoGlassTokens.sheetPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: VetoGlassTokens.glassBorder),
          ),
          title: Text(_t(code, 'deleteEvent'), style: const TextStyle(color: VetoGlassTokens.textPrimary)),
          content: Text(_t(code, 'deleteEventConfirm'),
              style: const TextStyle(color: VetoGlassTokens.textMuted)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t(code, 'cancel'),
                    style: const TextStyle(color: VetoGlassTokens.textMuted))),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: VetoPalette.emergency, foregroundColor: Colors.white),
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
          title: Text(
            '${_t(code, 'emergencyLogs')} (${_loading ? _t(code, 'loading') : _events.length})',
            style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
          ),
          centerTitle: true,
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: AppLanguageMenu(compact: true)),
            ),
            IconButton(icon: const Icon(Icons.refresh, color: VetoGlassTokens.textPrimary), onPressed: _load, tooltip: _t(code, 'refresh')),
          ],
          bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: VetoGlassTokens.glassBorder)),
        ),
        body: VetoGlassAuroraBackground(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: VetoGlassTokens.neonCyan))
            : _events.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_outline, color: VetoPalette.success, size: 48),
                    const SizedBox(height: 12),
                    Text(_t(code, 'noEmergencyEvents'), style: const TextStyle(color: VetoGlassTokens.textMuted)),
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
                          color: VetoGlassTokens.glassFillStrong,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: _sc(status), width: 3),
                            top: const BorderSide(color: VetoGlassTokens.glassBorder),
                            right: const BorderSide(color: VetoGlassTokens.glassBorder),
                            bottom: const BorderSide(color: VetoGlassTokens.glassBorder),
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
                              style: const TextStyle(color: VetoGlassTokens.textPrimary, fontWeight: FontWeight.w600),
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
                              icon: const Icon(Icons.delete_outline, size: 20, color: VetoPalette.emergency),
                              onPressed: eid.isEmpty ? null : () => _confirmDelete(eid),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(_fmt(e['triggered_at']?.toString()),
                              style: const TextStyle(color: VetoGlassTokens.textMuted, fontSize: 12)),
                          if (lawyer != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.gavel_rounded, color: VetoGlassTokens.accentSoft, size: 14),
                              const SizedBox(width: 4),
                              Text('${_t(code, 'lawyerPrefix')}: ${lawyer['full_name'] ?? lawyer['phone'] ?? ""}',
                                  style: const TextStyle(color: VetoGlassTokens.accentSoft, fontSize: 12)),
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
