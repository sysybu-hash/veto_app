import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_language.dart';
import '../../services/citizen_dashboard_api_service.dart';
import '../../widgets/citizen_mockup_shell.dart';

class CitizenNotificationsScreen extends StatefulWidget {
  const CitizenNotificationsScreen({super.key});

  @override
  State<CitizenNotificationsScreen> createState() => _CitizenNotificationsScreenState();
}

class _CitizenNotificationsScreenState extends State<CitizenNotificationsScreen> {
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
      final list = await CitizenDashboardApiService.instance.listNotifications();
      if (mounted) setState(() => _rows = list);
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
    return CitizenMockupShell(
      currentRoute: '/citizen_notifications',
      mobileNavIndex: citizenMobileNavIndexForRoute('/citizen_notifications'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(he ? 'התראות' : 'Notifications', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_err != null) Padding(padding: const EdgeInsets.all(16), child: Text(_err!, style: const TextStyle(color: Colors.red))),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final m = _rows[i] as Map<String, dynamic>;
                  final id = m['_id'] as String? ?? '';
                  final title = m['title'] as String? ?? '';
                  final body = m['body'] as String? ?? '';
                  final read = m['read'] == true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: read ? null : Colors.red.shade50,
                    child: ListTile(
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(body),
                      onTap: () async {
                        if (!read && id.isNotEmpty) {
                          try {
                            await CitizenDashboardApiService.instance.markNotificationRead(id);
                            await _load();
                          } catch (_) {}
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
