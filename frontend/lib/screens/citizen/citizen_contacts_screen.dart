import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../services/citizen_dashboard_api_service.dart';
import '../../widgets/citizen_mockup_shell.dart';
import '../../widgets/veto_dialogs.dart';

class CitizenContactsScreen extends StatefulWidget {
  const CitizenContactsScreen({super.key});

  @override
  State<CitizenContactsScreen> createState() => _CitizenContactsScreenState();
}

class _CitizenContactsScreenState extends State<CitizenContactsScreen> {
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
      final list = await CitizenDashboardApiService.instance.listContacts();
      if (mounted) setState(() => _rows = list);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final code = context.read<AppLanguageController>().code;
    final he = code == 'he';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(he ? 'איש קשר' : 'Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: he ? 'שם' : 'Name')),
            TextField(controller: phone, decoration: InputDecoration(labelText: he ? 'טלפון' : 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(he ? 'ביטול' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(he ? 'שמירה' : 'Save')),
        ],
      ),
    );
    if (ok != true || !mounted || name.text.trim().isEmpty) return;
    try {
      await CitizenDashboardApiService.instance.createContact({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
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
      message: he ? 'למחוק?' : 'Delete?',
      danger: true,
    );
    if (ok != true) return;
    try {
      await CitizenDashboardApiService.instance.deleteContact(id);
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
      currentRoute: '/citizen_contacts',
      mobileNavIndex: citizenMobileNavIndexForRoute('/citizen_contacts'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(he ? 'אנשי קשר' : 'Contacts', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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
                final name = m['name'] as String? ?? '';
                final phone = m['phone'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(phone),
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
