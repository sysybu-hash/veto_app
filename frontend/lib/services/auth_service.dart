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

  Future<bool> requestOTP(String phone, String role) async => await requestOtp(phone);

  Future<bool> requestOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/request-otp'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) return true;
    } catch (e) {
      debugPrint("Error requesting OTP: " + e.toString());
    }
    return false;
  }

  Future<OtpRequestOutcome> requestOTPDetailed(String phone, String role) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/request-otp'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) return OtpRequestOutcome.success;
      return OtpRequestOutcome.failure;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) return OtpRequestOutcome.timeout;
      return OtpRequestOutcome.failure;
    }
  }

  Future<Map<String, dynamic>?> verifyOTP(String phone, String otp) async {
    final res = await verifyOtp(phone, otp);
    if (res['success'] == true) return res;
    return null;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-otp'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'] ?? 'user';
        final user = data['user'];

        if (token != null) {
          await _storage.write(key: 'jwt', value: token);
          await _storage.write(key: 'veto_role', value: role);
          await _storage.write(key: 'veto_phone', value: phone);
                    
          if (user is Map<String, dynamic>) {
            final name = user['full_name']?.toString() ?? user['name']?.toString();
            if (name != null) await _storage.write(key: 'veto_name', value: name);
          }
        }
        return {'success': true, 'isNewUser': data['isNewUser'] == true, 'user': data['user']};
      }
      return {'success': false, 'error': jsonDecode(response.body)['error']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> register({required String fullName, required String phoneNumber, required String role, required String language}) async {
    final success = await updateProfile(name: fullName, role: role, language: language);
    if (success) await _storage.write(key: 'veto_phone', value: phoneNumber);
    return success;
  }

  Future<bool> updateProfile({required String name, required String role, required String language}) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/update-profile'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer ' + token}),
        body: jsonEncode({'full_name': name, 'role': role, 'language': language}),
      );
      if (response.statusCode == 200) {
        await _storage.write(key: 'veto_role', value: role);
        await _storage.write(key: 'veto_name', value: name);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile: ' + e.toString());
      return false;
    }
  }

  Future<String?> getToken() async => await _storage.read(key: 'jwt');
  Future<String?> getStoredRole() async => await _storage.read(key: 'veto_role');
  Future<String?> getStoredName() async => await _storage.read(key: 'veto_name');
  Future<String?> getStoredPhone() async => await _storage.read(key: 'veto_phone');

  Future<void> logout(BuildContext context) async {
    await _storage.deleteAll();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}