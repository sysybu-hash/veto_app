// ============================================================
//  webrtc_ice_config_service.dart — Fetch TURN from backend
//  STUN stays client-side; credentials only on server (.env).
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class WebRtcIceConfigService {
  WebRtcIceConfigService._();
  static final WebRtcIceConfigService instance = WebRtcIceConfigService._();

  /// Returns extra `iceServers` entries from `GET /api/calls/ice-config`, or null.
  Future<List<dynamic>?> fetchServerIceServers() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/calls/ice-config'),
            headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final list = body['iceServers'];
      if (list is! List || list.isEmpty) return null;
      return List<dynamic>.from(list);
    } catch (_) {
      return null;
    }
  }
}
