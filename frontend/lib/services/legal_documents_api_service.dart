// ============================================================
//  legal_documents_api_service.dart — generate + export legal docs
//  Calls /api/legal-documents/generate and /api/legal-documents/export
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../platform/browser_bridge.dart' as browser_bridge;
import 'auth_service.dart';

class LegalDocumentsApiService {
  LegalDocumentsApiService._();
  static final LegalDocumentsApiService instance = LegalDocumentsApiService._();

  static const Duration _timeout = Duration(seconds: 120);

  Future<Map<String, dynamic>?> generateDraft({
    required String domain,
    required String intent,
    required List<String> facts,
    String lang = 'he',
    String? title,
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) return null;
    final res = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/legal-documents/generate'),
          headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
          body: jsonEncode({
            'domain': domain,
            'intent': intent,
            'facts': facts,
            'lang': lang,
            if (title != null) 'title': title,
          }),
        )
        .timeout(_timeout)
        .catchError((Object e, StackTrace _) {
      debugPrint('generateDraft error: $e');
      return http.Response('{}', 500);
    });
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<bool> exportDocument({
    required String title,
    required String body,
    required String format, // pdf | docx
    String domain = 'כללי',
    String intent = 'מסמך משפטי',
    String lang = 'he',
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) return false;
    final res = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/legal-documents/export'),
          headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
          body: jsonEncode({
            'title': title,
            'body': body,
            'format': format,
            'domain': domain,
            'intent': intent,
            'lang': lang,
          }),
        )
        .timeout(_timeout)
        .catchError((Object e, StackTrace _) {
      debugPrint('exportDocument error: $e');
      return http.Response('{}', 500);
    });
    if (res.statusCode != 200) return false;

    if (kIsWeb) {
      final mime = format == 'docx'
          ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          : 'application/pdf';
      final b64 = base64Encode(res.bodyBytes);
      browser_bridge.openInNewTab('data:$mime;base64,$b64');
      return true;
    }
    return true;
  }
}
