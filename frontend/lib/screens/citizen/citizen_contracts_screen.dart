// ============================================================
//  citizen_contracts_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_2026.dart';
import '../../core/theme/veto_mockup_tokens.dart';
import '../../services/citizen_dashboard_api_service.dart';
import '../../widgets/citizen_mockup_shell.dart';
import '../../widgets/veto_dialogs.dart';

class CitizenContractsScreen extends StatefulWidget {
  const CitizenContractsScreen({super.key});

  @override
  State<CitizenContractsScreen> createState() => _CitizenContractsScreenState();
}

class _CitizenContractsScreenState extends State<CitizenContractsScreen> {
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
      final list = await CitizenDashboardApiService.instance.listContracts();
      if (mounted) setState(() => _rows = list);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final counterparty = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final code = context.read<AppLanguageController>().code;
        final he = code == 'he';
        return AlertDialog(
          title: Text(he ? 'חוזה חדש' : 'New contract'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: InputDecoration(labelText: he ? 'כותרת' : 'Title')),
              TextField(
                  controller: counterparty,
                  decoration: InputDecoration(labelText: he ? 'צד שני' : 'Counterparty')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(he ? 'ביטול' : 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(he ? 'שמירה' : 'Save')),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    if (title.text.trim().isEmpty) return;
    try {
      await CitizenDashboardApiService.instance.createContract({
        'title': title.text.trim(),
        'counterparty': counterparty.text.trim(),
        'status': 'active',
      });
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
      message: he ? 'למחוק חוזה?' : 'Delete this contract?',
      danger: true,
    );
    if (ok != true || !mounted) return;
    try {
      await CitizenDashboardApiService.instance.deleteContract(id);
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
      currentRoute: '/citizen_contracts',
      mobileNavIndex: citizenMobileNavIndexForRoute('/citizen_contracts'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  he ? 'חוזים' : 'Contracts',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
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
                final st = m['status'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(st),
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
