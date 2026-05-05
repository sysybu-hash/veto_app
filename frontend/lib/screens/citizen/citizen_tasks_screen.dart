import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../services/citizen_dashboard_api_service.dart';
import '../../widgets/citizen_mockup_shell.dart';
import '../../widgets/veto_dialogs.dart';

class CitizenTasksScreen extends StatefulWidget {
  const CitizenTasksScreen({super.key});

  @override
  State<CitizenTasksScreen> createState() => _CitizenTasksScreenState();
}

class _CitizenTasksScreenState extends State<CitizenTasksScreen> {
  List<dynamic> _rows = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final list = await CitizenDashboardApiService.instance.listTasks();
      if (mounted) setState(() => _rows = list);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final code = context.read<AppLanguageController>().code;
    final he = code == 'he';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(he ? 'משימה חדשה' : 'New task'),
        content: TextField(controller: title, decoration: InputDecoration(labelText: he ? 'כותרת' : 'Title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(he ? 'ביטול' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(he ? 'שמירה' : 'Save')),
        ],
      ),
    );
    if (ok != true || !mounted || title.text.trim().isEmpty) return;
    try {
      await CitizenDashboardApiService.instance.createTask({'title': title.text.trim(), 'status': 'open'});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleDone(Map<String, dynamic> m) async {
    final id = m['_id'] as String? ?? '';
    final st = m['status'] == 'done' ? 'open' : 'done';
    try {
      await CitizenDashboardApiService.instance.updateTask(id, {'status': st});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(String id) async {
    final code = context.read<AppLanguageController>().code;
    final he = code == 'he';
    final ok = await showVetoConfirmDialog<bool>(
      context: context,
      title: he ? 'מחיקה' : 'Delete',
      message: he ? 'למחוק משימה?' : 'Delete task?',
      danger: true,
    );
    if (ok != true) return;
    try {
      await CitizenDashboardApiService.instance.deleteTask(id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final he = code == 'he';
    return CitizenMockupShell(
      currentRoute: '/citizen_tasks',
      mobileNavIndex: citizenMobileNavIndexForRoute('/citizen_tasks'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(he ? 'משימות' : 'Tasks', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: Text(he ? 'חדש' : 'New')),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_err != null) Padding(padding: const EdgeInsets.all(16), child: Text(_err!, style: const TextStyle(color: Colors.red))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final m = _rows[i] as Map<String, dynamic>;
                final id = m['_id'] as String? ?? '';
                final title = m['title'] as String? ?? '';
                final done = m['status'] == 'done';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Checkbox(value: done, onChanged: (_) => _toggleDone(m)),
                    title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, decoration: done ? TextDecoration.lineThrough : null)),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(id)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
