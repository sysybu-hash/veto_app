import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

enum OtpRequestOutcome { success, failure, timeout }

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();

  Future<String?> requestOTPDetailed(String phone, String role) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/request-otp'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['otp']?.toString(); // null if not exposed
      }
      return 'error';
    } catch (e) {
      return 'error';
    }
  }

  Future<Map<String, dynamic>?> verifyOTP(String phone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-otp'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user'];
        
        // Correct role extraction from nested user object
        final role = user?['role']?.toString() ?? 'user';
        final name = user?['full_name']?.toString() ?? user?['name']?.toString() ?? '';

        if (token != null) {
          await _storage.write(key: 'jwt', value: token);
          await _storage.write(key: 'veto_role', value: role);
          await _storage.write(key: 'veto_phone', value: phone);
          if (name.isNotEmpty) await _storage.write(key: 'veto_name', value: name);
        }
        return {'success': true, 'user': user};
      }
      return null;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return null;
    }
  }

  Future<bool> register({
    required String fullName, 
    required String phoneNumber, 
    required String role, 
    required String language
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/register'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({
          'full_name': fullName,
          'phone': phoneNumber,
          'role': role,
          'preferred_language': language,
          'license_number': role == 'lawyer' ? '12345' : null // Simple default for demo
        }),
      );
      
      if (response.statusCode == 201) {
        await _storage.write(key: 'veto_phone', value: phoneNumber);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during registration: $e');
      return false;
    }
  }

  Future<String?> getToken() async => await _storage.read(key: 'jwt');
  Future<String?> getStoredRole() async => await _storage.read(key: 'veto_role');
  Future<String?> getStoredName() async => await _storage.read(key: 'veto_name');
  Future<String?> getStoredPhone() async => await _storage.read(key: 'veto_phone');

  /// Updates full_name on the server and in local storage.
  Future<bool> updateProfile({required String fullName}) async {
    try {
      final token = await getToken();
      final role = await getStoredRole();
      final baseUrl = AppConfig.baseUrl;
      // lawyers use /lawyers/me, users & admins use /users/me
      final endpoint = role == 'lawyer' ? '$baseUrl/lawyers/me' : '$baseUrl/users/me';
      final response = await http.put(
        Uri.parse(endpoint),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode({'full_name': fullName}),
      );
      if (response.statusCode == 200) {
        await _storage.write(key: 'veto_name', value: fullName);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    await _storage.deleteAll();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}