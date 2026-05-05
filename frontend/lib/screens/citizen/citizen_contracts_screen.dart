// ============================================================
//  citizen_contracts_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/veto_mockup_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/citizen_dashboard_api_service.dart';
import '../../services/legal_documents_api_service.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.citizenContractNewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: title,
                decoration: InputDecoration(labelText: l10n.citizenContractTitleLabel)),
            TextField(
                controller: counterparty,
                decoration:
                    InputDecoration(labelText: l10n.citizenContractPartyLabel)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _exportContract(
      Map<String, dynamic> m, String format, String code) async {
    final l10n = AppLocalizations.of(context)!;
    final title = (m['title'] as String?) ?? l10n.citizenContractNewTitle;
    final counterparty = (m['counterparty'] as String?) ?? '';
    final cp = counterparty.isEmpty ? '—' : counterparty;
    final status = (m['status'] as String?) ?? 'active';
    final body =
        '### ${l10n.citizenShellNavContracts}\n$title\n\n### ${l10n.citizenContractPartyLabel}\n$cp\n\n### $status';
    final ok = await LegalDocumentsApiService.instance.exportDocument(
      title: title,
      body: body,
      format: format,
      domain: 'contracts',
      intent: 'contract_export',
      lang: code,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (format == 'pdf' ? l10n.citizenExportPdfDone : l10n.citizenExportDocxDone)
          : l10n.citizenExportFailed),
    ));
  }

  Future<void> _delete(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showVetoConfirmDialog<bool>(
      context: context,
      title: l10n.commonDelete,
      message: l10n.citizenDeleteContractBody,
      danger: true,
    );
    if (ok != true || !mounted) return;
    try {
      await CitizenDashboardApiService.instance.deleteContract(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.citizenShellNavContracts,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
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
                final title = m['title'] as String? ?? '';
                final st = m['status'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(st),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.citizenContractExportPdfTooltip,
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              color: VetoMockup.primaryCta),
                          onPressed: () => _exportContract(m, 'pdf', code),
                        ),
                        IconButton(
                          tooltip: l10n.citizenContractExportDocxTooltip,
                          icon: const Icon(Icons.description_outlined,
                              color: VetoMockup.primaryCta),
                          onPressed: () => _exportContract(m, 'docx', code),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(id),
                        ),
                      ],
                    ),
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
