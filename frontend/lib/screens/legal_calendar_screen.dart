// ============================================================
//  Legal calendar — month / week / agenda, CRUD, iCal, Maps
// ============================================================

import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../core/theme/veto_mockup_tokens.dart';
import '../services/auth_service.dart';
import '../widgets/citizen_mockup_shell.dart';
import '../services/calendar_api_service.dart';
import '../services/gcal_api_service.dart';
import '../l10n/app_localizations.dart';

enum _CalView { month, week, agenda }

class _CaseOption {
  const _CaseOption({required this.id, required this.name});
  final String id;
  final String name;
}

String _calEventTypeLabel(AppLocalizations loc, String t) {
  switch (t) {
    case 'hearing':
      return loc.calScrTypeHearing;
    case 'meeting':
      return loc.calScrTypeMeeting;
    default:
      return loc.calScrTypeOther;
  }
}

Color _typeColor(String type) {
  switch (type) {
    case 'hearing':
      return V26.emerg;
    case 'meeting':
      return V26.navy600;
    default:
      return V26.ink500;
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// First day of week from Material (0=Sun … 6=Sat) → Dart weekday Mon=1…Sun=7.
int _firstWeekdayDart(int materialFirstDayIndex) =>
    materialFirstDayIndex == 0 ? 7 : materialFirstDayIndex;

DateTime _startOfWeekContaining(DateTime d, int materialFirstDayIndex) {
  final first = _firstWeekdayDart(materialFirstDayIndex);
  final wd = d.weekday;
  var diff = wd - first;
  if (diff < 0) diff += 7;
  final day = _dateOnly(d).subtract(Duration(days: diff));
  return day;
}

Set<(int, int)> _monthsSpanningRange(DateTime from, DateTime to) {
  final out = <(int, int)>{};
  var cur = _dateOnly(from);
  final end = _dateOnly(to);
  while (!cur.isAfter(end)) {
    out.add((cur.year, cur.month));
    cur = DateTime(cur.year, cur.month + 1, 1);
  }
  return out;
}

int _gridLeadingBlanks(DateTime firstOfMonth, int materialFirstDayIndex) {
  final first = _firstWeekdayDart(materialFirstDayIndex);
  final wd = firstOfMonth.weekday;
  var diff = wd - first;
  if (diff < 0) diff += 7;
  return diff;
}

class LegalCalendarScreen extends StatefulWidget {
  const LegalCalendarScreen({super.key});

  @override
  State<LegalCalendarScreen> createState() => _LegalCalendarScreenState();
}

class _LegalCalendarScreenState extends State<LegalCalendarScreen> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  final _api = CalendarApiService();
  final _gcalApi = GcalApiService();
  final _auth = AuthService();
  late final Future<String?> _citizenChromeFuture = _auth.getStoredRole();

  DateTime _focusDate = DateTime.now();
  _CalView _view = _CalView.month;
  DateTime? _selectedDay;
  bool _loading = true;
  List<CalendarEventDto> _items = const [];
  List<_CaseOption> _cases = const [];
  String? _icalHint;
  Map<String, dynamic>? _gcalStatus;

  int get _y => _focusDate.year;
  int get _m => _focusDate.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _dateOnly(_focusDate);
    unawaited(_loadCases());
    // _load uses MaterialLocalizations — must not run during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  String _icalDisplay(String? u) {
    if (u == null || u.isEmpty) return '';
    if (u.startsWith('http')) return u;
    return '${AppConfig.socketOrigin}$u';
  }

  Future<void> _loadCases() async {
    try {
      final tok = await _auth.getToken();
      if (tok == null) return;
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/vault/cases'),
            headers: AppConfig.httpHeaders({'Authorization': 'Bearer $tok'}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200 || !mounted) return;
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['cases'] ?? []);
      final opts = <_CaseOption>[];
      for (final e in list as List) {
        final m = e as Map<String, dynamic>;
        final id = '${m['_id'] ?? m['id'] ?? ''}';
        if (id.isEmpty) continue;
        final name = '${m['name'] ?? id}'.trim();
        opts.add(_CaseOption(id: id, name: name.isEmpty ? id : name));
      }
      opts.sort((a, b) => a.name.compareTo(b.name));
      setState(() => _cases = opts);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loc = MaterialLocalizations.of(context);
    List<CalendarEventDto> list;
    switch (_view) {
      case _CalView.month:
      case _CalView.agenda:
        list = await _api.listMonth(_y, _m);
        break;
      case _CalView.week:
        final anchor = _dateOnly(_focusDate);
        final w0 = _startOfWeekContaining(anchor, loc.firstDayOfWeekIndex);
        final w6 = w0.add(const Duration(days: 6));
        final months = _monthsSpanningRange(w0, w6);
        list = await _api.listMonths(months);
        list = list
            .where((e) {
              final ds = _dateOnly(e.start);
              return !ds.isBefore(w0) && !ds.isAfter(w6);
            })
            .toList();
        break;
    }
    final ical = await _api.icalUrl();
    final gcal = await _gcalApi.status();
    if (!mounted) return;
    setState(() {
      _items = list;
      _icalHint = ical;
      _gcalStatus = gcal;
      _loading = false;
    });
  }

  Future<void> _openGcalConnect() async {
    final url = await _gcalApi.connectAuthUrl();
    if (url == null || url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.calScrGcalNotConfigured)));
      return;
    }
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _gcalDisconnect() async {
    final ok = await _gcalApi.disconnect();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? _l10n.calScrGcalDisconnect : _l10n.calScrGenericError)),
    );
    await _load();
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

  void _stepPeriod(int delta) {
    final loc = MaterialLocalizations.of(context);
    switch (_view) {
      case _CalView.month:
      case _CalView.agenda:
        setState(() {
          _focusDate = DateTime(_y, _m + delta, 1);
          _selectedDay ??= _dateOnly(_focusDate);
        });
        break;
      case _CalView.week:
        setState(() {
          final w0 = _startOfWeekContaining(_focusDate, loc.firstDayOfWeekIndex);
          _focusDate = w0.add(Duration(days: 7 * delta));
        });
        break;
    }
    unawaited(_load());
  }

  List<CalendarEventDto> _eventsOnDay(DateTime day) {
    final d0 = _dateOnly(day);
    return _items.where((e) => _dateOnly(e.start) == d0).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<void> _showEventEditor({
    CalendarEventDto? existing,
    DateTime? suggestedStart,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final addrCtrl = TextEditingController(text: existing?.locationAddress ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var type = existing?.type ?? 'other';
    var reminders = Set<int>.from(existing?.reminderBeforeMinutes ?? const [15, 60]);
    String? caseId = existing?.sourceCaseId;

    var start = existing?.start ??
        suggestedStart ??
        DateTime(_y, _m, _selectedDay?.day ?? DateTime.now().day, 9, 0);
    var end = existing?.end ?? start.add(const Duration(hours: 1));

    if (!mounted) return;
    final sheetResult = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: V26.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: StatefulBuilder(
            builder: (context, setS) {
              Future<void> pickStart() async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: start,
                  firstDate: DateTime(_y - 2),
                  lastDate: DateTime(_y + 3),
                );
                if (d == null || !context.mounted) return;
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(start),
                );
                if (t == null || !context.mounted) return;
                setS(() {
                  start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                  if (!end.isAfter(start)) {
                    end = start.add(const Duration(hours: 1));
                  }
                });
              }

              Future<void> pickEnd() async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: end,
                  firstDate: DateTime(_y - 2),
                  lastDate: DateTime(_y + 3),
                );
                if (d == null || !context.mounted) return;
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(end),
                );
                if (t == null || !context.mounted) return;
                setS(() {
                  end = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                });
              }

              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.92,
                minChildSize: 0.45,
                maxChildSize: 0.95,
                builder: (context, scrollCtrl) {
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: V26.ink500.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        existing == null ? _l10n.calScrNewEvent : _l10n.calScrEditEvent,
                        style: const TextStyle(
                          color: V26.ink900,
                          fontFamily: V26.serif,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleCtrl,
                        style: const TextStyle(color: V26.ink900),
                        decoration: InputDecoration(
                          labelText: _l10n.calScrTitleField,
                          labelStyle: const TextStyle(color: V26.ink500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownMenu<String>(
                        initialSelection:
                            ['hearing', 'meeting', 'other'].contains(type) ? type : 'other',
                        label: Text(_l10n.calScrTypeField, style: const TextStyle(color: V26.ink500)),
                        dropdownMenuEntries: ['hearing', 'meeting', 'other']
                            .map(
                              (t) => DropdownMenuEntry(
                                value: t,
                                label: _calEventTypeLabel(_l10n, t),
                              ),
                            )
                            .toList(),
                        onSelected: (v) {
                          if (v != null) setS(() => type = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${_l10n.calScrStart}: ${start.toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(color: V26.ink700, fontSize: 14),
                        ),
                        trailing: const Icon(Icons.edit_calendar_outlined, color: V26.navy600),
                        onTap: pickStart,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${_l10n.calScrEnd}: ${end.toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(color: V26.ink700, fontSize: 14),
                        ),
                        trailing: const Icon(Icons.edit_calendar_outlined, color: V26.navy600),
                        onTap: pickEnd,
                      ),
                      TextField(
                        controller: addrCtrl,
                        style: const TextStyle(color: V26.ink900),
                        decoration: InputDecoration(
                          labelText: _l10n.calScrAddressField,
                          labelStyle: const TextStyle(color: V26.ink500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: V26.ink900),
                        decoration: InputDecoration(
                          labelText: _l10n.calScrNotesField,
                          labelStyle: const TextStyle(color: V26.ink500),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_l10n.calScrReminders, style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w600)),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final m in [15, 60, 1440])
                            FilterChip(
                              label: Text(m >= 1440 ? '24h' : '${m}m'),
                              selected: reminders.contains(m),
                              onSelected: (sel) => setS(() {
                                if (sel) {
                                  reminders.add(m);
                                } else {
                                  reminders.remove(m);
                                }
                              }),
                              selectedColor: V26.navy600.withValues(alpha: 0.2),
                              checkmarkColor: V26.navy600,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownMenu<String>(
                        initialSelection: caseId ?? '__none__',
                        label: Text(_l10n.calScrLinkCase, style: const TextStyle(color: V26.ink500)),
                        dropdownMenuEntries: [
                          DropdownMenuEntry(value: '__none__', label: _l10n.calScrNoCase),
                          ..._cases.map(
                            (c) => DropdownMenuEntry(value: c.id, label: c.name),
                          ),
                        ],
                        onSelected: (v) =>
                            setS(() => caseId = (v == '__none__') ? null : v),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (existing != null)
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, 2),
                              child: Text(_l10n.commonDelete, style: const TextStyle(color: V26.emerg)),
                            ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, 0),
                            child: Text(_l10n.commonCancel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, 1),
                            style: FilledButton.styleFrom(backgroundColor: V26.navy600),
                            child: Text(_l10n.commonSave),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );

    if (sheetResult == 1) {
      final t = titleCtrl.text.trim();
      if (t.isEmpty) {
        titleCtrl.dispose();
        addrCtrl.dispose();
        notesCtrl.dispose();
        return;
      }
      final rem = reminders.toList()..sort();
      if (existing == null) {
        await _api.create(
          title: t,
          start: start,
          end: end,
          type: type,
          locationAddress: addrCtrl.text.trim(),
          reminderBeforeMinutes: rem,
          notes: notesCtrl.text.trim(),
          sourceCaseId: caseId,
        );
      } else {
        await _api.updateEvent(
          id: existing.id,
          title: t,
          type: type,
          start: start,
          end: end,
          locationAddress: addrCtrl.text.trim(),
          reminderBeforeMinutes: rem,
          notes: notesCtrl.text.trim(),
          sourceCaseId: caseId,
          clearSourceCaseId: caseId == null,
        );
      }
    } else if (sheetResult == 2 && existing != null) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: V26.surface,
          title: Text(_l10n.calScrConfirmDeleteEvent, style: const TextStyle(color: V26.ink900)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_l10n.commonCancel)),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(_l10n.commonDelete, style: const TextStyle(color: V26.emerg)),
            ),
          ],
        ),
      );
      if (ok == true) {
        await _api.deleteEvent(existing.id);
      }
    }

    titleCtrl.dispose();
    addrCtrl.dispose();
    notesCtrl.dispose();
    if (mounted) await _load();
  }

  Widget _buildGcalCard() {
    final s = _gcalStatus;
    if (s == null) return const SizedBox.shrink();
    final enabled = s['enabled'] == true;
    if (!enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(_l10n.calScrGcalNotConfigured, style: const TextStyle(color: V26.ink500, fontSize: 12)),
      );
    }
    final connected = s['connected'] == true;
    final last = s['lastSyncAt'];
    return Material(
      color: V26.surface,
      child: ListTile(
        title: Text(_l10n.calScrGcalTitle, style: const TextStyle(color: V26.ink900, fontSize: 14)),
        subtitle: Text(
          connected
              ? '${_l10n.calScrGcalConnected}${last != null ? ' · $last' : ''}'
              : _l10n.calScrGcalConnect,
          style: const TextStyle(color: V26.ink500, fontSize: 12),
        ),
        trailing: connected
            ? TextButton(onPressed: () => _gcalDisconnect(), child: Text(_l10n.calScrGcalDisconnect))
            : TextButton(onPressed: () => _openGcalConnect(), child: Text(_l10n.calScrGcalConnect)),
      ),
    );
  }

  Widget _buildIcalCard() {
    if (_icalHint == null || _icalHint!.isEmpty) return const SizedBox.shrink();
    final display = _icalDisplay(_icalHint);
    return Material(
      color: V26.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_l10n.calScrIcalTitle, style: const TextStyle(color: V26.ink900, fontSize: 14)),
              subtitle: Text(
                display,
                style: const TextStyle(color: V26.ink500, fontSize: 11),
                maxLines: 3,
              ),
              trailing: IconButton(
                tooltip: _l10n.calScrCopyUrl,
                icon: const Icon(Icons.copy_rounded, color: V26.navy600),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: display));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.calScrCopied)));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(_l10n.calScrGoogleOutlookHint, style: TextStyle(color: V26.ink500.withValues(alpha: 0.9), fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SegmentedButton<_CalView>(
        segments: [
          ButtonSegment(value: _CalView.month, label: Text(_l10n.calScrMonthTab)),
          ButtonSegment(value: _CalView.week, label: Text(_l10n.calScrWeekTab)),
          ButtonSegment(value: _CalView.agenda, label: Text(_l10n.calScrAgendaTab)),
        ],
        selected: {_view},
        onSelectionChanged: (s) {
          setState(() => _view = s.first);
          unawaited(_load());
        },
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return V26.ink900;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return V26.navy600;
            return V26.surface;
          }),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(MaterialLocalizations loc) {
    final first = DateTime(_y, _m, 1);
    final daysInMonth = DateTime(_y, _m + 1, 0).day;
    final leading = _gridLeadingBlanks(first, loc.firstDayOfWeekIndex);
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final weekDays = () {
      final start = _firstWeekdayDart(loc.firstDayOfWeekIndex);
      const order = [1, 2, 3, 4, 5, 6, 7];
      final i = order.indexOf(start);
      return [...order.sublist(i), ...order.sublist(0, i)];
    }();

    String wdShort(int dartWeekday) {
      // narrowWeekdays: index 0 = Sunday … matches DateTime.weekday % 7
      return loc.narrowWeekdays[dartWeekday % 7];
    }

    return Column(
      children: [
        Row(
          children: [
            for (final wd in weekDays)
              Expanded(
                child: Center(
                  child: Text(
                    wdShort(wd),
                    style: const TextStyle(color: V26.ink500, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: totalCells,
          itemBuilder: (context, i) {
            final dayNum = i - leading + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(_y, _m, dayNum);
            final evs = _eventsOnDay(day);
            final sel = _selectedDay != null && _dateOnly(_selectedDay!) == day;
            return InkWell(
              onTap: () {
                setState(() => _selectedDay = day);
              },
              onLongPress: () => _showEventEditor(suggestedStart: DateTime(day.year, day.month, day.day, 9, 0)),
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sel ? V26.navy600.withValues(alpha: 0.12) : V26.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? V26.navy600 : V26.ink500.withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        color: sel ? V26.navy600 : V26.ink900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (evs.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var k = 0; k < evs.length.clamp(0, 3); k++)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: _typeColor(evs[k].type),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_selectedDay != null) ...[
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${_selectedDay!.day}/${_selectedDay!.month}',
                style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_eventsOnDay(_selectedDay!).isEmpty)
            Text(_l10n.calScrNoEvents, style: const TextStyle(color: V26.ink500))
          else
            ..._eventsOnDay(_selectedDay!).map(
              (e) => _eventTile(e),
            ),
        ],
      ],
    );
  }

  Widget _eventTile(CalendarEventDto e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: V26.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showEventEditor(existing: e),
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _typeColor(e.type),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(e.title, style: const TextStyle(color: V26.ink900, fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${e.start.toString().substring(11, 16)}–${e.end.toString().substring(11, 16)} · ${_calEventTypeLabel(_l10n, e.type)}'
          '${e.locationAddress.isNotEmpty ? '\n${e.locationAddress}' : ''}',
          style: const TextStyle(color: V26.ink500, fontSize: 12),
        ),
        isThreeLine: e.locationAddress.isNotEmpty,
        trailing: e.locationAddress.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.map_outlined, color: V26.navy600),
                onPressed: () => _openMaps(e.locationAddress),
              ),
      ),
    );
  }

  Widget _buildWeekView(MaterialLocalizations loc) {
    final w0 = _startOfWeekContaining(_focusDate, loc.firstDayOfWeekIndex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 7; i++)
          Builder(
            builder: (context) {
              final d = w0.add(Duration(days: i));
              final evs = _eventsOnDay(d);
              final today = _dateOnly(DateTime.now()) == d;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${d.day}/${d.month}',
                          style: TextStyle(
                            color: today ? V26.navy600 : V26.ink900,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          MaterialLocalizations.of(context).formatMediumDate(d),
                          style: const TextStyle(color: V26.ink500, fontSize: 13),
                        ),
                      ],
                    ),
                    if (evs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_l10n.calScrNoEvents, style: const TextStyle(color: V26.ink500, fontSize: 12)),
                      )
                    else
                      ...evs.map((e) => _eventTile(e)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAgenda() {
    final sorted = [..._items]..sort((a, b) => a.start.compareTo(b.start));
    if (sorted.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 48, bottom: 80),
        children: [
          Center(child: Text(_l10n.calScrNoEvents, style: const TextStyle(color: V26.ink500))),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) => _eventTile(sorted[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<AppLanguageController>().code;
    final loc = MaterialLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= V26AppShell.desktopBreakpoint;
    final periodLabel = switch (_view) {
      _CalView.week => () {
          final w0 = _startOfWeekContaining(_focusDate, loc.firstDayOfWeekIndex);
          final w1 = w0.add(const Duration(days: 6));
          return '${w0.day}/${w0.month}–${w1.day}/${w1.month} $_y';
        }(),
      _ => '$_m/$_y',
    };
    final statusText = '${_l10n.calScrTitle} · $periodLabel';

    final calendarBody = _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildIcalCard(),
              _buildGcalCard(),
              _buildViewToggle(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: _view == _CalView.agenda
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: _buildAgenda(),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                          child: _view == _CalView.week
                              ? _buildWeekView(loc)
                              : _buildMonthGrid(loc),
                        ),
                ),
              ),
            ],
          );

    final fabLegacy = FloatingActionButton.extended(
      onPressed: () => _showEventEditor(),
      backgroundColor: V26.navy600,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(_l10n.calScrAddEvent,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      heroTag: 'legal_cal_fab',
    );

    final fabCitizen = FloatingActionButton.extended(
      onPressed: () => _showEventEditor(),
      backgroundColor: VetoMockup.primaryCta,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(_l10n.calScrAddEvent,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      heroTag: 'legal_cal_fab',
    );

    return FutureBuilder<String?>(
      future: _citizenChromeFuture,
      builder: (context, snap) {
        final citizen = snap.data == 'user';
        if (citizen) {
          return Directionality(
            textDirection: AppLanguage.directionOf(code),
            child: CitizenMockupShell(
              currentRoute: '/legal_calendar',
              mobileNavIndex: citizenMobileNavIndexForRoute('/legal_calendar'),
              desktopTrailing: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: VetoMockup.ink),
                  tooltip: _l10n.calScrToolbarRefresh,
                  onPressed: _loading ? null : _load,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: VetoMockup.ink),
                  tooltip: _l10n.calScrPrev,
                  onPressed: _loading ? null : () => _stepPeriod(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: VetoMockup.ink),
                  tooltip: _l10n.calScrNext,
                  onPressed: _loading ? null : () => _stepPeriod(1),
                ),
              ],
              floatingActionButton: fabCitizen,
              mobileAppBar: AppBar(
                backgroundColor: VetoMockup.surfaceCard,
                foregroundColor: VetoMockup.ink,
                elevation: 0,
                title: Text(
                  '${_l10n.calScrTitle} · $periodLabel',
                  style: const TextStyle(
                    fontFamily: V26.serif,
                    fontWeight: FontWeight.w800,
                    color: VetoMockup.ink,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: _l10n.calScrToolbarRefresh,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh, color: VetoMockup.ink),
                  ),
                  IconButton(
                    tooltip: _l10n.calScrPrev,
                    onPressed: _loading ? null : () => _stepPeriod(-1),
                    icon: const Icon(Icons.chevron_right, color: VetoMockup.ink),
                  ),
                  IconButton(
                    tooltip: _l10n.calScrNext,
                    onPressed: _loading ? null : () => _stepPeriod(1),
                    icon: const Icon(Icons.chevron_left, color: VetoMockup.ink),
                  ),
                ],
              ),
              child: calendarBody,
            ),
          );
        }
        return Directionality(
          textDirection: AppLanguage.directionOf(code),
          child: V26AppShell(
            destinations: isWide
                ? V26CitizenNav.destinations(code)
                : V26CitizenNav.bottomDestinations(code),
            currentIndex: isWide ? 3 : -1,
            onDestinationSelected: (i) {
              final routes =
                  isWide ? V26CitizenNav.routes : V26CitizenNav.bottomRoutes;
              V26CitizenNav.go(context, routes[i], current: '/legal_calendar');
            },
            desktopStatusText: statusText,
            desktopTrailing: [
              V26IconBtn(
                icon: Icons.refresh_rounded,
                tooltip: _l10n.calScrToolbarRefresh,
                onTap: _loading ? null : _load,
              ),
              const SizedBox(width: 8),
              V26IconBtn(
                icon: Icons.chevron_right,
                tooltip: _l10n.calScrPrev,
                onTap: _loading ? null : () => _stepPeriod(-1),
              ),
              const SizedBox(width: 8),
              V26IconBtn(
                icon: Icons.chevron_left,
                tooltip: _l10n.calScrNext,
                onTap: _loading ? null : () => _stepPeriod(1),
              ),
            ],
            mobileAppBar: AppBar(
              backgroundColor: V26.surface,
              foregroundColor: V26.ink900,
              elevation: 0,
              title: Text(
                '${_l10n.calScrTitle} · $periodLabel',
                style: const TextStyle(
                  fontFamily: V26.serif,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: _l10n.calScrToolbarRefresh,
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: _l10n.calScrPrev,
                  onPressed: _loading ? null : () => _stepPeriod(-1),
                  icon: const Icon(Icons.chevron_right),
                ),
                IconButton(
                  tooltip: _l10n.calScrNext,
                  onPressed: _loading ? null : () => _stepPeriod(1),
                  icon: const Icon(Icons.chevron_left),
                ),
              ],
            ),
            floatingAction: fabLegacy,
            child: calendarBody,
          ),
        );
      },
    );
  }
}
