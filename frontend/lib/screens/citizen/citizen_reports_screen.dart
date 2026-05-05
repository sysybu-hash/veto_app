import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../services/citizen_dashboard_api_service.dart';
import '../../widgets/citizen_mockup_shell.dart';

class CitizenReportsScreen extends StatefulWidget {
  const CitizenReportsScreen({super.key});

  @override
  State<CitizenReportsScreen> createState() => _CitizenReportsScreenState();
}

class _CitizenReportsScreenState extends State<CitizenReportsScreen> {
  Map<String, dynamic>? _data;
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
      final m = await CitizenDashboardApiService.instance.fetchReportsSummary();
      if (mounted) setState(() => _data = m);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final he = code == 'he';
    final totals = _data?['totals'] as Map<String, dynamic>?;
    return CitizenMockupShell(
      currentRoute: '/citizen_reports',
      mobileNavIndex: citizenMobileNavIndexForRoute('/citizen_reports'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(he ? 'דוחות' : 'Reports', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
            if (totals != null)
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(totals),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}
