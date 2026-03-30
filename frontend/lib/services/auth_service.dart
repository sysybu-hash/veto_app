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

  /// Render free tier can take 60s+ to wake; keep below browser limits.
  static const Duration _httpTimeout = Duration(seconds: 90);

  Future<bool> requestOtp(String phone, {String role = 'admin'}) async {
    final r = await requestOtpDetailed(phone, role: role);
    return r == OtpRequestOutcome.success;
  }

  Future<OtpRequestOutcome> requestOtpDetailed(String phone,
      {String role = 'admin'}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/request-otp');
    try {
      final response = await http
          .post(
            uri,
            headers: AppConfig.httpHeaders({}),
            body: jsonEncode({'phone': phone, 'role': role}),
          )
          .timeout(_httpTimeout);
      if (response.statusCode == 200) return OtpRequestOutcome.success;
      debugPrint(
          '⚠️ request-otp ${response.statusCode} ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      return OtpRequestOutcome.failed;
    } on TimeoutException {
      debugPrint('⚠️ request-otp timeout → $uri');
      return OtpRequestOutcome.timeout;
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
          .timeout(_httpTimeout);

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
