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

  /// Same as [uploadRecording] but reports bytes consumed by the request body (chunked read).
  Future<void> uploadRecordingWithProgress({
    required String eventId,
    required Uint8List bytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final token = await _auth.getToken();
    if (token == null || eventId.isEmpty || bytes.isEmpty) return;
    onProgress?.call(0, bytes.length);

    Stream<List<int>> chunkOut() async* {
      const chunk = 32 * 1024;
      for (var i = 0; i < bytes.length; i += chunk) {
        final j = (i + chunk < bytes.length) ? i + chunk : bytes.length;
        onProgress?.call(j, bytes.length);
        yield bytes.sublist(i, j);
      }
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/calls/$eventId/recording'),
    );
    request.headers.addAll(
      AppConfig.httpHeadersBinary({'Authorization': 'Bearer $token'}),
    );
    request.files.add(
      http.MultipartFile(
        'recording',
        http.ByteStream(chunkOut()),
        bytes.length,
        filename: fileName,
      ),
    );

    final response = await request.send();
    onProgress?.call(bytes.length, bytes.length);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errBody = await response.stream.bytesToString();
      throw Exception('Recording upload failed (${response.statusCode}): $errBody');
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
