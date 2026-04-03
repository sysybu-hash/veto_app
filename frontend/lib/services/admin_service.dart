import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class AdminService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> getAdminSettings() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/settings'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Failed to get admin settings: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching admin settings: $e');
      return null;
    }
  }

  Future<bool> updateFixedOtpSetting(bool enable) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/admin/settings/fixed-otp'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode({'enable': enable}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to update fixed OTP setting: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating fixed OTP setting: $e');
      return false;
    }
  }
}