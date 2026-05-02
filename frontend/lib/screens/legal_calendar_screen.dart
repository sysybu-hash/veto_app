// ============================================================
//  LegalCalendarScreen — VETO 2026
//  Tokens-aligned. Month list of legal events + create + open in maps.
// ============================================================
import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/theme/veto_tokens_2026.dart';
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

  static const _monthsHe = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _icalDisplay(String? u) {
    if (u == null || u.isEmpty) return '';
    if (u.startsWith('http')) return u;
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
    unawaited(launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      mode: LaunchMode.externalApplication,
    ));
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
              title: Text('אירוע חדש', style: VetoTokens.titleLg),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'כותרת', prefixIcon: Icon(Icons.title_rounded, size: 16)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addrCtrl,
                        decoration: const InputDecoration(labelText: 'כתובת (לניווט)', prefixIcon: Icon(Icons.location_on_outlined, size: 16)),
                      ),
                      const SizedBox(height: 12),
                      _DateTimeRow(
                        label: 'התחלה',
                        value: pickedStart,
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: pickedStart, firstDate: DateTime(_y - 1), lastDate: DateTime(_y + 2));
                          if (d == null || !context.mounted) return;
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(pickedStart));
                          if (t == null || !context.mounted) return;
                          setS(() => pickedStart = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        },
                      ),
                      const SizedBox(height: 8),
                      _DateTimeRow(
                        label: 'סיום',
                        value: pickedEnd,
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: pickedEnd, firstDate: DateTime(_y - 1), lastDate: DateTime(_y + 2));
                          if (d == null || !context.mounted) return;
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(pickedEnd));
                          if (t == null || !context.mounted) return;
                          setS(() => pickedEnd = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: VetoTokens.navy600, foregroundColor: Colors.white),
                  child: const Text('שמור'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      final t = titleCtrl.text.trim();
      if (t.isNotEmpty) {
        await _api.create(
          title: t,
          start: pickedStart,
          end: pickedEnd,
          locationAddress: addrCtrl.text.trim(),
          reminderBeforeMinutes: const [15, 60],
        );
      }
    }
    titleCtrl.dispose();
    addrCtrl.dispose();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VetoTokens.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('יומן משפטי', style: VetoTokens.titleLg),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded, size: 18), tooltip: 'רענן'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: VetoTokens.navy600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('אירוע חדש', style: VetoTokens.labelMd.copyWith(color: Colors.white)),
        heroTag: 'legal_cal_fab',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: VetoTokens.navy600))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    // Month nav
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: VetoTokens.cardDecoration(radius: VetoTokens.rPill),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 18),
                              onPressed: () { if (_m == 1) { _m = 12; _y--; } else { _m--; } unawaited(_load()); },
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '${_monthsHe[_m - 1]} $_y',
                                  style: VetoTokens.serif(18, FontWeight.w800, color: VetoTokens.ink900),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 18),
                              onPressed: () { if (_m == 12) { _m = 1; _y++; } else { _m++; } unawaited(_load()); },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_icalHint != null && _icalHint!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VetoTokens.infoSoft,
                            borderRadius: BorderRadius.circular(VetoTokens.rMd),
                            border: Border.all(color: const Color(0xFFC4D4F4), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_note_rounded, size: 16, color: VetoTokens.navy700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('iCal · לסנכרון עם יומן חיצוני', style: VetoTokens.bodyXs.copyWith(color: VetoTokens.navy700, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text(_icalDisplay(_icalHint),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: VetoTokens.bodyXs.copyWith(color: VetoTokens.navy600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: _items.isEmpty
                          ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(32),
                                decoration: VetoTokens.cardDecoration(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64, height: 64,
                                      decoration: BoxDecoration(color: VetoTokens.paper2, borderRadius: BorderRadius.circular(20)),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.event_busy_rounded, size: 28, color: VetoTokens.ink300),
                                    ),
                                    const SizedBox(height: 12),
                                    Text('אין אירועים החודש', style: VetoTokens.serif(18, FontWeight.w700, color: VetoTokens.ink900)),
                                    const SizedBox(height: 4),
                                    Text('לחץ על "אירוע חדש" כדי ליצור.', style: VetoTokens.bodySm.copyWith(color: VetoTokens.ink500), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) => _EventCard(event: _items[i], onMaps: () => _openMaps(_items[i].locationAddress)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VetoTokens.rSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: VetoTokens.surface2,
          border: Border.all(color: VetoTokens.hairline),
          borderRadius: BorderRadius.circular(VetoTokens.rSm),
        ),
        child: Row(children: [
          const Icon(Icons.schedule_rounded, size: 16, color: VetoTokens.navy600),
          const SizedBox(width: 10),
          Text(label, style: VetoTokens.titleSm.copyWith(color: VetoTokens.ink700)),
          const Spacer(),
          Text(value.toLocal().toString().substring(0, 16),
              style: VetoTokens.bodyMd.copyWith(color: VetoTokens.ink900, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left_rounded, size: 18, color: VetoTokens.ink300),
        ]),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onMaps});
  final CalendarEventDto event;
  final VoidCallback onMaps;

  @override
  Widget build(BuildContext context) {
    final start = event.start.toLocal();
    final end = event.end.toLocal();
    final dayLabel = '${start.day}/${start.month}';
    final timeLabel = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} — ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(VetoTokens.rMd),
        border: const Border(
          left: BorderSide(color: VetoTokens.navy600, width: 3),
          top: BorderSide(color: VetoTokens.hairline),
          right: BorderSide(color: VetoTokens.hairline),
          bottom: BorderSide(color: VetoTokens.hairline),
        ),
        boxShadow: VetoTokens.shadow1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50, padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: VetoTokens.navy100, borderRadius: BorderRadius.circular(VetoTokens.rSm)),
            child: Column(
              children: [
                Text('${start.day}', style: VetoTokens.serif(20, FontWeight.w900, color: VetoTokens.navy700, height: 1.0)),
                Text(_monthShort(start.month), style: VetoTokens.bodyXs.copyWith(color: VetoTokens.navy600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: VetoTokens.titleMd.copyWith(color: VetoTokens.ink900)),
                const SizedBox(height: 2),
                Text('$dayLabel · $timeLabel', style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                if (event.locationAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: VetoTokens.ink500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(event.locationAddress,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: VetoTokens.bodyXs.copyWith(color: VetoTokens.ink500)),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          if (event.locationAddress.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined, size: 18, color: VetoTokens.navy600),
              onPressed: onMaps,
              tooltip: 'נווט',
            ),
        ],
      ),
    );
  }

  String _monthShort(int m) {
    const months = ['ינו', 'פבר', 'מרץ', 'אפר', 'מאי', 'יונ', 'יול', 'אוג', 'ספט', 'אוק', 'נוב', 'דצמ'];
    return months[(m - 1).clamp(0, 11)];
  }
}
