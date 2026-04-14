import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class CallApiService {
  final AuthService _auth = AuthService();

  Future<void> uploadRecording({
    required String eventId,
    required Uint8List bytes,
    required String mimeType,
    required String fileName,
  }) async {
    final token = await _auth.getToken();
    if (token == null || eventId.isEmpty || bytes.isEmpty) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/calls/$eventId/recording'),
    );
    request.headers.addAll(
      AppConfig.httpHeadersBinary({'Authorization': 'Bearer $token'}),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'recording',
        bytes,
        filename: fileName,
      ),
    );

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw Exception('Recording upload failed (${response.statusCode}): $body');
    }
  }

  Future<String?> transcribeRecording({
    required String eventId,
    required Uint8List bytes,
    required String mimeType,
    required String language,
  }) async {
    final token = await _auth.getToken();
    if (token == null || eventId.isEmpty || bytes.isEmpty) return null;

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/calls/$eventId/transcribe'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      body: jsonEncode({
        'audioBase64': base64Encode(bytes),
        'mimeType': mimeType,
        'language': language,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Transcription failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['transcript']?.toString();
  }
}
