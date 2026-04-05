import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  /// Send a chat message to the AI backend.
  /// [history] — list of previous exchanges in Gemini format:
  ///   [{ 'role': 'user'|'model', 'parts': [{'text': '...'}] }, ...]
  Future<Map<String, dynamic>> chat({
    required String message,
    required List<Map<String, dynamic>> history,
    String lang = 'he',
  }) async {
    try {
      final token = await AuthService().getToken();
      final resp = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/ai/chat'),
            headers: AppConfig.httpHeaders({
              if (token != null) 'Authorization': 'Bearer $token',
            }),
            body: jsonEncode({'message': message, 'history': history, 'lang': lang}),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return {'classified': false, 'reply': 'שגיאה בחיבור לשירות ה-AI'};
    } catch (_) {
      return {'classified': false, 'reply': 'שגיאה בחיבור לשירות ה-AI'};
    }
  }
}
