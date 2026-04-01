import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Outcome for request-otp (timeout = common on Render free cold start).
enum OtpRequestOutcome { success, failed, timeout }

class AuthService {
  final _storage = const FlutterSecureStorage();

  /// POST ל-API — אחרי cold start בדרך כלל מהיר.
  static const Duration _postTimeout = Duration(seconds: 120);

  /// GET /health רק כדי לעורר אינסטנס; לא לחסום דקות שלמות לפני ה-POST.
  static const Duration _healthPingTimeout = Duration(seconds: 45);

  Future<bool> requestOtp(String phone, {String role = 'admin'}) async {
    final r = await requestOtpDetailed(phone, role: role);
    return r == OtpRequestOutcome.success;
  }

  /// GET /health — מעורר שירות רדום; נתעלם משגיאות.
  Future<void> _pingHealth(Duration timeout) async {
    try {
      await http
          .get(
            Uri.parse(AppConfig.healthCheckUrl),
            headers: AppConfig.httpGetHeaders,
          )
          .timeout(timeout);
    } catch (_) {}
  }

  Future<OtpRequestOutcome> _postRequestOtp(
    String phone,
    String role,
    Duration timeout,
  ) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/request-otp');
    final response = await http
        .post(
          uri,
          headers: AppConfig.httpHeaders({}),
          body: jsonEncode({'phone': phone, 'role': role}),
        )
        .timeout(timeout);
    if (response.statusCode == 200) return OtpRequestOutcome.success;
    debugPrint(
        '⚠️ request-otp ${response.statusCode} ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
    return OtpRequestOutcome.failed;
  }

  Future<OtpRequestOutcome> requestOtpDetailed(String phone,
      {String role = 'admin'}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/request-otp');
    await _pingHealth(_healthPingTimeout);
    try {
      return await _postRequestOtp(phone, role, _postTimeout);
    } on TimeoutException {
      debugPrint('⚠️ request-otp timeout, retry (server may be warm now) → $uri');
      try {
        return await _postRequestOtp(phone, role, _postTimeout);
      } on TimeoutException {
        debugPrint('⚠️ request-otp timeout after retry → $uri');
        return OtpRequestOutcome.timeout;
      }
    } catch (e) {
      debugPrint('⚠️ request-otp error: $e');
      return OtpRequestOutcome.failed;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String phone, String code) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/auth/verify-otp'),
            headers: AppConfig.httpHeaders({}),
            body: jsonEncode({'phone': phone, 'otp': code}),
          )
          .timeout(_postTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) return null;
        final token = data['token'] as String?;
        if (token == null || token.isEmpty) return null;

        await _storage.write(key: 'jwt', value: token);

        final user = data['user'];
        final role = user is Map<String, dynamic>
            ? (user['role']?.toString() ?? 'user')
            : 'user';
        await _storage.write(key: 'veto_role', value: role);

        return data;
      }
      return null;
    } on TimeoutException {
      debugPrint('⚠️ verify-otp timeout');
      return null;
    } catch (e) {
      debugPrint('⚠️ verify-otp error: $e');
      return null;
    }
  }

  Future<OtpRequestOutcome> requestOTPDetailed(String phone, String role) =>
      requestOtpDetailed(phone, role: role);

  Future<bool> requestOTP(String phone, String role) =>
      requestOtp(phone, role: role);

  Future<Map<String, dynamic>?> verifyOTP(String phone, String otp) =>
      verifyOtp(phone, otp);

  Future<bool> register({
    required String fullName,
    required String phoneNumber,
    String role = 'user',
    String language = 'he',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/auth/register'),
            headers: AppConfig.httpHeaders({}),
            body: jsonEncode({
              'full_name': fullName,
              'phone': phoneNumber,
              'role': role,
              'preferred_language': language,
            }),
          )
          .timeout(_postTimeout);

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('⚠️ register error: $e');
      return false;
    }
  }

  Future<String?> getStoredRole() async =>
      await _storage.read(key: 'veto_role');

  /// Prefer `jwt`; fall back to legacy `veto_token` during storage-key migration.
  Future<String?> getToken() async {
    final jwt = await _storage.read(key: 'jwt');
    if (jwt != null && jwt.isNotEmpty) return jwt;
    final legacy = await _storage.read(key: 'veto_token');
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return null;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
