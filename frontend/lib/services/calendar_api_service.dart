// ============================================================
//  Calendar API (JWT)
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class CalendarEventDto {
  CalendarEventDto({
    required this.id,
    required this.title,
    required this.type,
    required this.start,
    required this.end,
    this.timezone = 'Asia/Jerusalem',
    this.locationAddress = '',
    this.locationLatLng,
    this.reminderBeforeMinutes = const [],
    this.notes = '',
    this.sourceCaseId,
  });

  final String id;
  final String title;
  final String type;
  final DateTime start;
  final DateTime end;
  final String timezone;
  final String locationAddress;
  final Map<String, double>? locationLatLng;
  final List<int> reminderBeforeMinutes;
  final String notes;
  final String? sourceCaseId;

  static CalendarEventDto fromJson(Map<String, dynamic> j) {
    final idRaw = j['_id'] ?? j['id'];
    final id = idRaw == null ? '' : idRaw.toString();
    return CalendarEventDto(
      id: id,
      title: j['title'] as String? ?? '',
      type: j['type'] as String? ?? 'other',
      start: DateTime.parse(j['start'] as String).toLocal(),
      end: DateTime.parse(j['end'] as String).toLocal(),
      timezone: j['timezone'] as String? ?? 'Asia/Jerusalem',
      locationAddress: j['locationAddress'] as String? ?? '',
      locationLatLng: (j['locationLatLng'] is Map)
          ? {
              'lat': (j['locationLatLng']['lat'] as num?)?.toDouble() ?? 0,
              'lng': (j['locationLatLng']['lng'] as num?)?.toDouble() ?? 0,
            }
          : null,
      reminderBeforeMinutes: (j['reminderBeforeMinutes'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      notes: j['notes'] as String? ?? '',
      sourceCaseId: j['sourceCaseId'] as String?,
    );
  }
}

class CalendarApiService {
  Future<String?> _token() => AuthService().getToken();

  Future<List<CalendarEventDto>> listMonth(int year, int month) async {
    final t = await _token();
    if (t == null) return [];
    final u = Uri.parse('${AppConfig.baseUrl}/calendar/events').replace(
      queryParameters: {
        'year': '$year',
        'month': '$month',
      },
    );
    final r = await http.get(
      u,
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    if (r.statusCode != 200) return [];
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (j['events'] as List<dynamic>?) ?? [];
    return list
        .map((e) => CalendarEventDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CalendarEventDto?> create({
    required String title,
    required DateTime start,
    required DateTime end,
    String type = 'other',
    String timezone = 'Asia/Jerusalem',
    String locationAddress = '',
    Map<String, double>? locationLatLng,
    List<int> reminderBeforeMinutes = const [15, 60],
    String notes = '',
    String? sourceCaseId,
  }) async {
    final t = await _token();
    if (t == null) return null;
    final body = <String, dynamic>{
      'title': title,
      'start': start.toUtc().toIso8601String(),
      'end': end.toUtc().toIso8601String(),
      'type': type,
      'timezone': timezone,
      'locationAddress': locationAddress,
      'reminderBeforeMinutes': reminderBeforeMinutes,
      'notes': notes,
    };
    if (locationLatLng != null) {
      body['locationLatLng'] = locationLatLng;
    }
    if (sourceCaseId != null && sourceCaseId.isNotEmpty) {
      body['sourceCaseId'] = sourceCaseId;
    }
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/calendar/events'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
      body: jsonEncode(body),
    );
    if (r.statusCode != 201) return null;
    return CalendarEventDto.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  Future<CalendarEventDto?> getEvent(String id) async {
    final t = await _token();
    if (t == null) return null;
    final r = await http.get(
      Uri.parse('${AppConfig.baseUrl}/calendar/events/${Uri.encodeComponent(id)}'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    if (r.statusCode != 200) return null;
    return CalendarEventDto.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  Future<CalendarEventDto?> updateEvent({
    required String id,
    String? title,
    String? type,
    DateTime? start,
    DateTime? end,
    String? timezone,
    String? locationAddress,
    Map<String, double>? locationLatLng,
    List<int>? reminderBeforeMinutes,
    String? notes,
    String? sourceCaseId,
    bool clearSourceCaseId = false,
  }) async {
    final t = await _token();
    if (t == null) return null;
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (type != null) body['type'] = type;
    if (start != null) body['start'] = start.toUtc().toIso8601String();
    if (end != null) body['end'] = end.toUtc().toIso8601String();
    if (timezone != null) body['timezone'] = timezone;
    if (locationAddress != null) body['locationAddress'] = locationAddress;
    if (locationLatLng != null) body['locationLatLng'] = locationLatLng;
    if (reminderBeforeMinutes != null) {
      body['reminderBeforeMinutes'] = reminderBeforeMinutes;
    }
    if (notes != null) body['notes'] = notes;
    if (clearSourceCaseId) {
      body['sourceCaseId'] = null;
    } else if (sourceCaseId != null) {
      body['sourceCaseId'] = sourceCaseId;
    }
    final r = await http.put(
      Uri.parse('${AppConfig.baseUrl}/calendar/events/${Uri.encodeComponent(id)}'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) return null;
    return CalendarEventDto.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  Future<bool> deleteEvent(String id) async {
    final t = await _token();
    if (t == null) return false;
    final r = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/calendar/events/${Uri.encodeComponent(id)}'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    return r.statusCode == 200;
  }

  /// Merge events for [months] as (year, month) pairs (dedupe by id).
  Future<List<CalendarEventDto>> listMonths(Iterable<(int, int)> months) async {
    final seen = <String>{};
    final out = <CalendarEventDto>[];
    for (final ym in months) {
      final list = await listMonth(ym.$1, ym.$2);
      for (final e in list) {
        if (seen.add(e.id)) out.add(e);
      }
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  Future<String?> icalUrl() async {
    final t = await _token();
    if (t == null) return null;
    final r = await http.get(
      Uri.parse('${AppConfig.baseUrl}/calendar/feed'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return j['webcalUrl'] as String?;
  }
}
