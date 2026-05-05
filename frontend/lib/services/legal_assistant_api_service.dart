// ============================================================
//  legal_assistant_api_service.dart — context-aware AI assistant
//  Calls POST /api/legal-assistant/context-chat with route+role.
//  Falls back to /api/ai/chat if the new endpoint returns 404.
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class LegalAssistantApiService {
  LegalAssistantApiService._();
  static final LegalAssistantApiService instance = LegalAssistantApiService._();

  static const Duration _timeout = Duration(seconds: 90);

  Future<Map<String, dynamic>> contextChat({
    required String message,
    required List<Map<String, dynamic>> history,
    required String route,
    required String role,
    String lang = 'he',
    String action = '',
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      return {
        'ok': false,
        'reply': 'נדרש להתחבר מחדש כדי להשתמש בעוזר המשפטי.',
      };
    }
    final url =
        Uri.parse('${AppConfig.baseUrl}/legal-assistant/context-chat');
    try {
      final res = await http
          .post(
            url,
            headers: AppConfig.httpHeaders({
              'Authorization': 'Bearer $token',
            }),
            body: jsonEncode({
              'message': message,
              'history': history,
              'route': route,
              'role': role,
              'lang': lang,
              'action': action,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'ok': true,
          'reply': (body['reply'] ?? '').toString(),
          'role': body['role'],
          'route': body['route'],
        };
      }
      if (res.statusCode == 401) {
        return {
          'ok': false,
          'reply': 'נדרש להתחבר מחדש כדי להשתמש בעוזר המשפטי.',
        };
      }
      if (res.statusCode == 403) {
        return {
          'ok': false,
          'reply': 'אין לך הרשאה לפעולה זו.',
        };
      }
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final err = body['error']?.toString();
        return {
          'ok': false,
          'reply': err ?? 'שגיאה (${res.statusCode}) בעוזר המשפטי.',
        };
      } catch (_) {
        return {
          'ok': false,
          'reply': 'שגיאה (${res.statusCode}) בעוזר המשפטי.',
        };
      }
    } catch (e) {
      debugPrint('LegalAssistantApiService.contextChat failed: $e');
      return {
        'ok': false,
        'reply': 'לא ניתן להגיע לעוזר המשפטי כעת.',
      };
    }
  }
}
