import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/veto_theme.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});
  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard> {
  String _lawyerName = '...';
  String _phone = '';
  String _role  = 'lawyer';
  bool _isAvailable = true;
  final List<Map<String, dynamic>> _alerts = [];
  StreamSubscription? _alertSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth  = AuthService();
    final name  = await auth.getStoredName();
    final phone = await auth.getStoredPhone();
    final role  = await auth.getStoredRole() ?? 'lawyer';
    if (!mounted) return;
    setState(() {
      _lawyerName = (name != null && name.isNotEmpty) ? name : 'עורך דין';
      _phone = phone ?? '';
      _role  = role;
    });
    await SocketService().connect(role: role);
    SocketService().emit('lawyer_availability', {'available': _isAvailable});
    _alertSub = SocketService().onNewEmergencyAlert.listen((data) {
      if (!mounted) return;
      setState(() => _alerts.add(data));
      _showAlert(data);
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  void _toggleAvailability(bool v) {
    setState(() => _isAvailable = v);
    SocketService().emit('lawyer_availability', {'available': v});
  }

  void _acceptCase(Map<String, dynamic> c) {
    SocketService().emit('accept_case', {'eventId': c['eventId']});
    setState(() {
      _alerts.removeWhere((x) => x['eventId'] == c['eventId']);
      _isAvailable = false;
    });
    SocketService().emit('lawyer_availability', {'available': false});
    _snack('\u05D4\u05EA\u05D9\u05E7 \u05D4\u05EA\u05E7\u05D1\u05DC \u05D1\u05D4\u05E6\u05DC\u05D7\u05D4 ✓', ok: true);
  }

  void _rejectCase(Map<String, dynamic> c) {
    SocketService().emit('reject_case', {'eventId': c['eventId']});
    setState(() => _alerts.removeWhere((x) => x['eventId'] == c['eventId']));
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? VetoPalette.success : VetoPalette.emergency,
    ));
  }

  void _showAlert(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AlertDialog(
        data: data,
        onAccept: () { Navigator.pop(context); _acceptCase(data); },
        onReject: () { Navigator.pop(context); _rejectCase(data); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VetoPalette.bg,
        body: SafeArea(
          child: Column(children: [
            _TopBar(name: _lawyerName, phone: _phone, role: _role,
                isAdmin: _role == 'admin'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      _StatusCard(
                          isAvailable: _isAvailable,
                          onToggle: _toggleAvailability),
                      const SizedBox(height: 16),
                      _StatsRow(
                          pending: _alerts.length,
                          available: _isAvailable),
                      const SizedBox(height: 20),
                      if (_alerts.isEmpty)
                        _EmptyState()
                      else ...[
                        _secLabel(
                            '\u05E7\u05E8\u05D9\u05D0\u05D5\u05EA \u05D7\u05D9\u05E8\u05D5\u05DD \u05E4\u05E2\u05D9\u05DC\u05D5\u05EA (${_alerts.length})'),
                        const SizedBox(height: 8),
                        ..._alerts.map((a) => _CaseCard(
                            data: a,
                            onAccept: () => _acceptCase(a),
                            onReject: () => _rejectCase(a))),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _secLabel(String t) => Text(t,
      style: const TextStyle(
          color: VetoPalette.textMuted, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.8));
}

class _TopBar extends StatelessWidget {
  final String name, phone, role;
  final bool isAdmin;
  const _TopBar({required this.name, required this.phone,
      required this.role, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
          color: VetoPalette.surface,
          border: Border(bottom: BorderSide(color: VetoPalette.border))),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: VetoPalette.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: VetoPalette.primary.withValues(alpha: 0.3))),
          child: const Icon(Icons.gavel_rounded, color: VetoPalette.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('\u05E7\u05D5\u05E0\u05E1\u05D5\u05DC\u05EA \u05E2\u05D5"\u05D3',
                style: TextStyle(color: VetoPalette.textMuted, fontSize: 10,
                    letterSpacing: 1)),
            Text('\u05E2\u05D5"\u05D3 $name',
                style: const TextStyle(color: VetoPalette.text,
                    fontWeight: FontWeight.w700, fontSize: 15)),
            if (phone.isNotEmpty)
              Text(phone,
                  style: const TextStyle(color: VetoPalette.textSubtle,
                      fontSize: 10),
                  textDirection: TextDirection.ltr),
          ]),
        ),
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            color: VetoPalette.primary,
            onPressed: () => Navigator.pushNamed(context, '/admin_settings'),
          ),
        IconButton(
            icon: const Icon(Icons.person_outline),
            color: VetoPalette.textMuted,
            onPressed: () => Navigator.pushNamed(context, '/profile')),
        IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: VetoPalette.textMuted,
            onPressed: () => AuthService().logout(context)),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onToggle;
  const _StatusCard({required this.isAvailable, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? VetoPalette.success : VetoPalette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('\u05E1\u05D8\u05D8\u05D5\u05E1 \u05D6\u05DE\u05D9\u05E0\u05D5\u05EA',
                style: TextStyle(color: VetoPalette.textMuted, fontSize: 11)),
            Text(
              isAvailable
                  ? '\u05D6\u05DE\u05D9\u05DF \u05DC\u05E7\u05E8\u05D9\u05D0\u05D5\u05EA'
                  : '\u05DC\u05D0 \u05D6\u05DE\u05D9\u05DF',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ]),
        ),
        Switch(
            value: isAvailable, onChanged: onToggle,
            activeTrackColor: VetoPalette.success),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int pending;
  final bool available;
  const _StatsRow({required this.pending, required this.available});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _statCard('\u05E7\u05E8\u05D9\u05D0\u05D5\u05EA \u05DE\u05DE\u05EA\u05D9\u05E0\u05D5\u05EA',
          '$pending', Icons.notification_important_rounded,
          pending > 0 ? VetoPalette.emergency : VetoPalette.textMuted)),
      const SizedBox(width: 12),
      Expanded(child: _statCard('\u05E1\u05D8\u05D8\u05D5\u05E1',
          available ? '\u05D6\u05DE\u05D9\u05DF' : '\u05DC\u05D0 \u05D6\u05DE\u05D9\u05DF',
          Icons.circle, available ? VetoPalette.success : VetoPalette.textMuted,
          textSize: 13)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      {double textSize = 22}) =>
    Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
          color: VetoPalette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VetoPalette.border)),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(color: color, fontSize: textSize,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: VetoPalette.textMuted, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VetoPalette.border)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_rounded,
          size: 48, color: VetoPalette.textMuted.withValues(alpha: 0.4)),
      const SizedBox(height: 14),
      const Text('\u05D0\u05D9\u05DF \u05E7\u05E8\u05D9\u05D0\u05D5\u05EA \u05E4\u05E2\u05D9\u05DC\u05D5\u05EA',
          style: TextStyle(color: VetoPalette.textMuted, fontSize: 15)),
      const SizedBox(height: 4),
      const Text('\u05E7\u05E8\u05D9\u05D0\u05D5\u05EA \u05D7\u05D9\u05E8\u05D5\u05DD \u05D9\u05D5\u05E4\u05D9\u05E2\u05D5 \u05DB\u05D0\u05DF \u05D1\u05E7\u05E8\u05D5\u05D1',
          style: TextStyle(color: VetoPalette.textSubtle, fontSize: 12)),
    ]),
  );
}

class _CaseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAccept, onReject;
  const _CaseCard({required this.data, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final userId  = data['userId']?.toString() ?? '—';
    final details = data['details']?.toString() ?? '\u05D0\u05D9\u05DF \u05E4\u05E8\u05D8\u05D9\u05DD';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VetoPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetoPalette.emergency.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: VetoPalette.emergency.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('\u05E7\u05E8\u05D9\u05D0\u05EA \u05D7\u05D9\u05E8\u05D5\u05DD',
                  style: TextStyle(color: VetoPalette.emergency, fontSize: 10,
                      fontWeight: FontWeight.w700))),
          const Spacer(),
          Text(userId,
              style: const TextStyle(color: VetoPalette.textSubtle, fontSize: 11),
              textDirection: TextDirection.ltr),
        ]),
        const SizedBox(height: 10),
        Text(details,
            style: const TextStyle(color: VetoPalette.text, fontSize: 13, height: 1.5)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                  foregroundColor: VetoPalette.textMuted,
                  side: const BorderSide(color: VetoPalette.border)),
              child: const Text('\u05D3\u05D7\u05D4'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(backgroundColor: VetoPalette.success),
              child: const Text('\u05E7\u05D1\u05DC \u05EA\u05D9\u05E7'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _AlertDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAccept, onReject;
  const _AlertDialog({required this.data, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: VetoPalette.emergency, size: 26),
          SizedBox(width: 10),
          Text('\u05E7\u05E8\u05D9\u05D0\u05EA \u05D7\u05D9\u05E8\u05D5\u05DD',
              style: TextStyle(color: VetoPalette.text, fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _row('\u05DE\u05E9\u05EA\u05DE\u05E9', data['userId']?.toString() ?? '—'),
          const SizedBox(height: 6),
          _row('\u05E4\u05E8\u05D8\u05D9\u05DD', data['details']?.toString() ?? '\u05D0\u05D9\u05DF'),
        ]),
        actions: [
          TextButton(onPressed: onReject,
              child: const Text('\u05D3\u05D7\u05D4',
                  style: TextStyle(color: VetoPalette.textMuted))),
          FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(backgroundColor: VetoPalette.success),
            child: const Text('\u05E7\u05D1\u05DC \u05EA\u05D9\u05E7',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$l: ', style: const TextStyle(color: VetoPalette.textMuted, fontSize: 12)),
      Expanded(child: Text(v,
          style: const TextStyle(color: VetoPalette.text, fontSize: 12))),
    ],
  );
}
