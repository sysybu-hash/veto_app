// ============================================================
//  Legal calendar — month list, create, open in Maps
// ============================================================

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../services/calendar_api_service.dart';

class LegalCalendarScreen extends StatefulWidget {
  const LegalCalendarScreen({super.key});

  @override
  State<LegalCalendarScreen> createState() => _LegalCalendarScreenState();
}

class _LegalCalendarScreenState extends State<LegalCalendarScreen> {
  final _api = CalendarApiService();
  int _y = DateTime.now().year;
  int _m = DateTime.now().month;
  bool _loading = true;
  List<CalendarEventDto> _items = const [];
  String? _icalHint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _icalDisplay(String? u) {
    if (u == null || u.isEmpty) return '';
    if (u.startsWith('http')) return u;
    // Server did not set PUBLIC_API_BASE; prefix current API origin
    return '${AppConfig.socketOrigin}$u';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.listMonth(_y, _m);
    final ical = await _api.icalUrl();
    if (!mounted) return;
    setState(() {
      _items = list;
      _icalHint = ical;
      _loading = false;
    });
  }

  void _openMaps(String address) {
    if (address.trim().isEmpty) return;
    final q = Uri.encodeComponent(address);
    unawaited(
      launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
        mode: LaunchMode.externalApplication,
      ),
    );
  }

  Future<void> _add() async {
    final titleCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    var pickedStart = DateTime(_y, _m, 15, 9, 0);
    var pickedEnd = pickedStart.add(const Duration(hours: 1));
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setS) {
            return AlertDialog(
              backgroundColor: V26.surface,
              title: const Text('אירוע חדש', style: TextStyle(color: V26.ink900)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: V26.ink900),
                      decoration: const InputDecoration(
                        labelText: 'כותרת',
                        labelStyle: TextStyle(color: V26.ink500),
                      ),
                    ),
                    TextField(
                      controller: addrCtrl,
                      style: const TextStyle(color: V26.ink900),
                      decoration: const InputDecoration(
                        labelText: 'כתובת (לניווט)',
                        labelStyle: TextStyle(color: V26.ink500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(
                        'התחלה: ${pickedStart.toLocal().toString().substring(0, 16)}',
                        style: const TextStyle(color: V26.ink500, fontSize: 13),
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: pickedStart,
                          firstDate: DateTime(_y - 1),
                          lastDate: DateTime(_y + 2),
                        );
                        if (d == null) return;
                        if (!context.mounted) return;
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(pickedStart),
                        );
                        if (t == null) return;
                        if (!context.mounted) return;
                        setS(() {
                          pickedStart = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        });
                      },
                    ),
                    ListTile(
                      title: Text(
                        'סיום: ${pickedEnd.toLocal().toString().substring(0, 16)}',
                        style: const TextStyle(color: V26.ink500, fontSize: 13),
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: pickedEnd,
                          firstDate: DateTime(_y - 1),
                          lastDate: DateTime(_y + 2),
                        );
                        if (d == null) return;
                        if (!context.mounted) return;
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(pickedEnd),
                        );
                        if (t == null) return;
                        if (!context.mounted) return;
                        setS(() {
                          pickedEnd = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ביטול'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('שמירה'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      final t = titleCtrl.text.trim();
      if (t.isEmpty) {
        titleCtrl.dispose();
        addrCtrl.dispose();
        return;
      }
      await _api.create(
        title: t,
        start: pickedStart,
        end: pickedEnd,
        locationAddress: addrCtrl.text.trim(),
        reminderBeforeMinutes: const [15, 60],
      );
    }
    titleCtrl.dispose();
    addrCtrl.dispose();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final isWide =
        MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;
    final statusText = code == 'he'
        ? 'יומן משפטי · $_m/$_y'
        : (code == 'ru'
            ? 'Юр. календарь · $_m/$_y'
            : 'Legal calendar · $_m/$_y');
    return Directionality(
      textDirection: AppLanguage.directionOf(code),
      child: V26AppShell(
      destinations: isWide
          ? V26CitizenNav.destinations(code)
          : V26CitizenNav.bottomDestinations(code),
      currentIndex: isWide ? 3 /* יומן */ : -1,
      onDestinationSelected: (i) {
        final routes = isWide
            ? V26CitizenNav.routes
            : V26CitizenNav.bottomRoutes;
        V26CitizenNav.go(context, routes[i], current: '/legal_calendar');
      },
      desktopStatusText: statusText,
      desktopTrailing: [
        V26IconBtn(
          icon: Icons.refresh_rounded,
          tooltip: 'רענון',
          onTap: _loading ? null : _load,
        ),
        const SizedBox(width: 8),
        V26IconBtn(
          icon: Icons.chevron_right,
          tooltip: 'חודש קודם',
          onTap: _loading
              ? null
              : () {
                  if (_m == 1) {
                    _m = 12;
                    _y--;
                  } else {
                    _m--;
                  }
                  unawaited(_load());
                },
        ),
        const SizedBox(width: 8),
        V26IconBtn(
          icon: Icons.chevron_left,
          tooltip: 'חודש הבא',
          onTap: _loading
              ? null
              : () {
                  if (_m == 12) {
                    _m = 1;
                    _y++;
                  } else {
                    _m++;
                  }
                  unawaited(_load());
                },
        ),
      ],
      mobileAppBar: AppBar(
        backgroundColor: V26.surface,
        foregroundColor: V26.ink900,
        elevation: 0,
        title: Text(
          'יומן משפטי · $_m/$_y',
          style: const TextStyle(
            fontFamily: V26.serif,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'רענון',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'חודש קודם',
            onPressed: _loading
                ? null
                : () {
                    if (_m == 1) {
                      _m = 12;
                      _y--;
                    } else {
                      _m--;
                    }
                    unawaited(_load());
                  },
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'חודש הבא',
            onPressed: _loading
                ? null
                : () {
                    if (_m == 12) {
                      _m = 1;
                      _y++;
                    } else {
                      _m++;
                    }
                    unawaited(_load());
                  },
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
      floatingAction: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: V26.navy600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('אירוע',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        heroTag: 'legal_cal_fab',
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_icalHint != null && _icalHint!.isNotEmpty)
                  Material(
                    color: V26.surface,
                    child: ListTile(
                      title: const Text(
                        'iCal (לסנכרון)',
                        style: TextStyle(color: V26.ink900, fontSize: 14),
                      ),
                      subtitle: Text(
                        _icalDisplay(_icalHint),
                        style: const TextStyle(color: V26.ink500, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Text('אין אירועים בחודש', style: TextStyle(color: V26.ink500)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final e = _items[i];
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor: V26.surface,
                              title: Text(
                                e.title,
                                style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${e.start.toString().substring(0, 16)} — ${e.end.toString().substring(0, 16)}'
                                '${e.locationAddress.isNotEmpty ? '\n${e.locationAddress}' : ''}'
                                    .trim(),
                                style: const TextStyle(color: V26.ink500, fontSize: 12),
                              ),
                              isThreeLine: e.locationAddress.isNotEmpty,
                              trailing: e.locationAddress.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.map_outlined, color: V26.navy600),
                                      onPressed: () => _openMaps(e.locationAddress),
                                    ),
                            );
                          },
                        ),
                ),
              ],
            ),
      ),
    );
  }
}
