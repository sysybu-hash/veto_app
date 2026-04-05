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

  Future<List<dynamic>> getAllUsers() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/users'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)['users'] as List?) ?? [];
      }
    } catch (e) { debugPrint('getAllUsers error: $e'); }
    return [];
  }

  Future<Map<String, dynamic>?> createUser(Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/admin/users'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('createUser failed: ${response.statusCode} ${response.body}');
    } catch (e) { debugPrint('createUser error: $e'); }
    return null;
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/admin/users/$id'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) { debugPrint('updateUser error: $e'); return false; }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/admin/users/$id'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) { debugPrint('deleteUser error: $e'); return false; }
  }

  Future<List<dynamic>> getAllLawyers() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/lawyers'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)['lawyers'] as List?) ?? [];
      }
    } catch (e) { debugPrint('getAllLawyers error: $e'); }
    return [];
  }

  Future<Map<String, dynamic>?> createLawyer(Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/admin/lawyers'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('createLawyer failed: ${response.statusCode} ${response.body}');
    } catch (e) { debugPrint('createLawyer error: $e'); }
    return null;
  }

  Future<bool> updateLawyer(String id, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/admin/lawyers/$id'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) { debugPrint('updateLawyer error: $e'); return false; }
  }

  Future<bool> deleteLawyer(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/admin/lawyers/$id'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) { debugPrint('deleteLawyer error: $e'); return false; }
  }

  Future<List<dynamic>> getEmergencyLogs() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/emergency-logs'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)['events'] as List?) ?? [];
      }
    } catch (e) { debugPrint('getEmergencyLogs error: $e'); }
    return [];
  }

  Future<bool> updateEmergencyLog(String id, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/admin/emergency-logs/$id'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) { debugPrint('updateEmergencyLog error: $e'); return false; }
  }

  Future<bool> deleteEmergencyLog(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/admin/emergency-logs/$id'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) { debugPrint('deleteEmergencyLog error: $e'); return false; }
  }
}