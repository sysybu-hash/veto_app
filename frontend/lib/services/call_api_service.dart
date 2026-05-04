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
      throw Exception(
          'Recording upload failed (${response.statusCode}): $body');
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
      throw Exception(
          'Recording upload failed (${response.statusCode}): $errBody');
    }
  }

  /// When [EmergencyEvent.recording_url] is set (e.g. after upload), the server
  /// fetches the file and transcribes — no inline [audioBase64] required.
  Future<String?> transcribeFromStoredRecording({
    required String eventId,
    required String language,
  }) async {
    final token = await _auth.getToken();
    if (token == null || eventId.isEmpty) return null;

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/calls/$eventId/transcribe'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      body: jsonEncode({'language': language}),
    );

    if (response.statusCode == 400) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 503) return null;
      throw Exception(
        'Transcription failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['transcript']?.toString();
  }

  /// Issues / renews an Agora RTC token for [eventId] via
  /// `POST /api/calls/:eventId/token` (see `agoraToken.service.js`).
  /// Returns a JSON map with `agoraToken`, `agoraUid`, `channelId`,
  /// `ttlSec`, `expiresAt` — or `null` when the server refuses.
  Future<Map<String, dynamic>?> fetchFreshAgoraToken(String eventId) async {
    final token = await _auth.getToken();
    if (token == null ||
        eventId.isEmpty ||
        !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(eventId)) {
      return null;
    }
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/calls/$eventId/token'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  /// Agora Cloud Recording — composite mix (full channel) for web browsers.
  /// Returns `null` when not configured (503) or on network failure.
  Future<Map<String, dynamic>?> startCloudRecording({
    required String eventId,
    required bool wantVideo,
  }) async {
    final token = await _auth.getToken();
    if (token == null || eventId.isEmpty) return null;
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/calls/$eventId/cloud-recording/start'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      body: jsonEncode({'wantVideo': wantVideo}),
    );
    if (response.statusCode == 503) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  /// Stops cloud recording. Response may include `pending: true` while the
  /// server uploads to Cloudinary — poll [fetchCallRecordingUrl] until non-empty.
  Future<Map<String, dynamic>?> stopCloudRecording(String eventId) async {
    final token = await _auth.getToken();
    if (token == null || eventId.isEmpty) return null;
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/calls/$eventId/cloud-recording/stop'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      body: jsonEncode(<String, dynamic>{}),
    );
    if (response.statusCode == 503) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  /// `recording_url` on the emergency event (after cloud finalize or client upload).
  Future<String?> fetchCallRecordingUrl(String eventId) async {
    final token = await _auth.getToken();
    if (token == null || eventId.isEmpty) return null;
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/calls/$eventId'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final call = decoded['call'];
    if (call is! Map) return null;
    final u = call['recording_url']?.toString();
    if (u == null || u.isEmpty) return null;
    return u;
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
