// ============================================================
//  upload_service.dart — Cloud Evidence Upload Service
//  VETO Legal Emergency App
//  Sends photo/video/audio + metadata to the backend API.
//  Backend proxies to S3 / Cloudinary in production.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';

class UploadResult {
  final bool    success;
  final String? cloudUrl;
  final String? error;
  const UploadResult({required this.success, this.cloudUrl, this.error});
}

class UploadService {
  // ── Singleton ──────────────────────────────────────────────
  static final UploadService _i = UploadService._();
  factory UploadService() => _i;
  UploadService._();

  // ── Upload evidence file ───────────────────────────────────
  /// [file]      — the captured image/video/audio file
  /// [type]      — 'photo' | 'video' | 'audio'
  /// [eventId]   — links the file to the active VETO session
  /// [lat]/[lng] — GPS coordinates at capture time
  /// [token]     — bearer JWT from auth
  /// [onProgress]— 0.0 → 1.0 progress callback
  Future<UploadResult> uploadEvidence({
    required File   file,
    required String type,
    required String eventId,
    required double lat,
    required double lng,
    required String token,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uri =
          Uri.parse('${AppConfig.baseUrl}/events/$eventId/evidence/upload');

      // ── Determine MIME type ──────────────────────────────
      final mime = _mimeFor(type, file.path);

      // ── Build multipart request (binary: bypass tunnel, no JSON Content-Type)
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(
          AppConfig.httpHeadersBinary({'Authorization': 'Bearer $token'}),
        )
        ..fields['type']            = type
        ..fields['latitude']        = lat.toString()
        ..fields['longitude']       = lng.toString()
        ..fields['client_timestamp'] = DateTime.now().toUtc().toIso8601String()
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: mime,
        ));

      // ── Track progress via stream ────────────────────────
      final streamedResponse = await request.send();
      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      final responseBytes = <int>[];
      await for (final chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
        }
      }

      if (streamedResponse.statusCode == 201) {
        final body = json.decode(utf8.decode(responseBytes));
        final cloudUrl = body['evidence']?['cloud_url'] as String?;
        onProgress?.call(1.0);
        return UploadResult(success: true, cloudUrl: cloudUrl);
      } else {
        final body = json.decode(utf8.decode(responseBytes));
        return UploadResult(
          success: false,
          error: body['error'] ?? 'Upload failed (${streamedResponse.statusCode})',
        );
      }
    } catch (e) {
      return UploadResult(success: false, error: e.toString());
    }
  }

  // ── MIME helper ───────────────────────────────────────────
  MediaType _mimeFor(String type, String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (type) {
      case 'video':
        return MediaType('video', ext == 'mov' ? 'quicktime' : 'mp4');
      case 'audio':
        return MediaType('audio', ext == 'm4a' ? 'mp4' : ext);
      default: // photo
        return MediaType('image', ext == 'jpg' ? 'jpeg' : ext);
    }
  }
}
