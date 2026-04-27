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
    String locationAddress = '',
    List<int> reminderBeforeMinutes = const [15, 60],
    String notes = '',
  }) async {
    final t = await _token();
    if (t == null) return null;
    final body = {
      'title': title,
      'start': start.toUtc().toIso8601String(),
      'end': end.toUtc().toIso8601String(),
      'type': type,
      'timezone': 'Asia/Jerusalem',
      'locationAddress': locationAddress,
      'reminderBeforeMinutes': reminderBeforeMinutes,
      'notes': notes,
    };
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
