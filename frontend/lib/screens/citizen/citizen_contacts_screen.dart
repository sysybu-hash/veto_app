import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.citizenContactDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.citizenContactNameLabel)),
            TextField(
                controller: phone,
                decoration: InputDecoration(labelText: l10n.citizenContactPhoneLabel)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonSave)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _delete(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showVetoConfirmDialog<bool>(
      context: context,
      title: l10n.commonDelete,
      message: l10n.citizenDeleteContactBody,
      danger: true,
    );
    if (ok != true) return;
    try {
      await CitizenDashboardApiService.instance.deleteContact(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppLanguageController>();
    final l10n = AppLocalizations.of(context)!;
    return CitizenMockupShell(
      currentRoute: '/citizen_contacts',
      mobileNavIndex: citizenMobileNavIndexForRoute('/citizen_contacts'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(l10n.citizenShellNavContacts,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                FilledButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.citizenBtnNew)),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_err != null)
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_err!, style: const TextStyle(color: Colors.red))),
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
                    trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(id)),
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
