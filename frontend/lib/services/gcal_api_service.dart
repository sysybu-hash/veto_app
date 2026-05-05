// ============================================================
//  Google Calendar integration status / OAuth helpers (JWT)
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class GcalApiService {
  Future<String?> _token() => AuthService().getToken();

  /// { enabled, connected, calendarId?, lastSyncAt?, message? }
  Future<Map<String, dynamic>?> status() async {
    final t = await _token();
    if (t == null) return null;
    final r = await http.get(
      Uri.parse('${AppConfig.baseUrl}/integrations/gcal/status'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    if (r.statusCode != 200) return null;
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Returns Google consent URL to open in browser / WebView.
  Future<String?> connectAuthUrl() async {
    final t = await _token();
    if (t == null) return null;
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/integrations/gcal/connect'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return j['authUrl'] as String?;
  }

  Future<bool> disconnect() async {
    final t = await _token();
    if (t == null) return false;
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/integrations/gcal/disconnect'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    return r.statusCode == 200;
  }
}
