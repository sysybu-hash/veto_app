import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  /// Gemini (esp. Pro) + cold Render can exceed short client timeouts.
  static const Duration _chatTimeout = Duration(seconds: 120);

  Future<void> _warmUpBackend() async {
    try {
      await http
          .get(
            Uri.parse(AppConfig.healthCheckUrl),
            headers: AppConfig.httpGetHeaders,
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // Best-effort warmup — ignore failures.
    }
  }

  Map<String, dynamic> _fallbackReply(String msg) => {
        'classified': false,
        'reply': msg,
      };

  /// Avoid showing raw Google API JSON blobs in the chat UI.
  String _friendlyServerDetail(String detail) {
    final t = detail.trim();
    if (t.startsWith('{') && t.contains('"error"')) {
      try {
        final m = jsonDecode(t) as Map<String, dynamic>?;
        final e = m?['error'];
        if (e is Map) {
          final code = e['code'];
          final status = e['status'];
          final em = (e['message'] ?? '').toString();
          if (code == 503 ||
              status == 'UNAVAILABLE' ||
              em.toLowerCase().contains('high demand')) {
            return 'המודל עמוס כרגע. נסה שוב בעוד רגע.';
          }
        }
      } catch (_) {}
    }
    return detail;
  }

  /// Send a chat message to the AI backend.
  /// [history] — list of previous exchanges in Gemini format:
  ///   [{ 'role': 'user'|'model', 'parts': [{'text': '...'}] }, ...]
  Future<Map<String, dynamic>> chat({
    required String message,
    required List<Map<String, dynamic>> history,
    String lang = 'he',
  }) async {
    try {
      // Render free instances may be asleep; wake the backend first.
      await _warmUpBackend();

      final token = await AuthService().getToken();
      final resp = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/ai/chat'),
            headers: AppConfig.httpHeaders({
              if (token != null) 'Authorization': 'Bearer $token',
            }),
            body: jsonEncode({'message': message, 'history': history, 'lang': lang}),
          )
          .timeout(_chatTimeout);

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      if (resp.statusCode == 429) {
        try {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          return {
            'classified': false,
            'reply': body['reply'] ?? 'השירות עמוס, נסה שוב בעוד כמה שניות.',
          };
        } catch (_) {
          return {
            'classified': false,
            'reply': 'השירות עמוס, נסה שוב בעוד כמה שניות.',
          };
        }
      }
      if (resp.statusCode == 503) {
        try {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          final msg = body['error'] as String?;
          return {
            'classified': false,
            'reply': msg ?? 'שירות ה-AI לא הוגדר בשרת.',
          };
        } catch (_) {
          return _fallbackReply('שירות ה-AI לא זמין כרגע.');
        }
      }
      // Try to surface backend error details for easier debugging.
      try {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final err = body['detail'] ?? body['error'];
        final raw = err is Map
            ? jsonEncode(err)
            : (err ?? '').toString().trim();
        if (raw.isNotEmpty) {
          return _fallbackReply(_friendlyServerDetail(raw));
        }
      } catch (_) {}
      return _fallbackReply('שגיאה בחיבור לשירות ה-AI (קוד ${resp.statusCode})');
    } on TimeoutException catch (e, st) {
      debugPrint('AiService.chat timeout: $e\n$st');
      return _fallbackReply(
        'התשובה מהשרת ארכה יותר מדי. נסה שוב בעוד רגע — אם זה חוזר, בדוק חיבור לאינטרנט.',
      );
    } catch (e) {
      debugPrint('AiService.chat failed: $e');
      debugPrint('AiService.chat baseUrl=${AppConfig.baseUrl} health=${AppConfig.healthCheckUrl}');
      // On Flutter web this commonly surfaces as "XMLHttpRequest error." (CORS / network / blocked).
      final msg = 'שגיאה בחיבור לשירות ה-AI. (${e.toString()})';
      return _fallbackReply(msg);
    }
  }
}
