import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<bool> requestOtp(String phone, {String role = 'admin'}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/request-otp'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({'phone': phone, 'role': role}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String phone, String code) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-otp'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({'phone': phone, 'otp': code}),
      );

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
    } catch (e) {
      return null;
    }
  }

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
