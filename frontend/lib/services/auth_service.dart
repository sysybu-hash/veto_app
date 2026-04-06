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

  // Web uses localStorage via flutter_secure_storage_web.
  // We pass WebOptions so the key prefix is consistent across browsers.
  // Note: incognito mode in some browsers restricts localStorage — handled
  // gracefully because every read/write is inside try/catch in this class.
  static const _kWebOptions = WebOptions(
    dbName: 'veto_secure',
    publicKey: 'veto',
  );
  final _storage = const FlutterSecureStorage(
    webOptions: _kWebOptions,
  );

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
        final preferredLanguage = user?['preferred_language']?.toString() ?? 'he';

        if (token != null) {
          await _storage.write(key: 'jwt', value: token);
          await _storage.write(key: 'veto_role', value: role);
          await _storage.write(key: 'veto_phone', value: phone);
          if (name.isNotEmpty) await _storage.write(key: 'veto_name', value: name);
          await _storage.write(key: 'veto_language', value: preferredLanguage);
          final isSubscribed = user?['is_subscribed'] == true;
          await _storage.write(key: 'veto_subscribed', value: isSubscribed ? 'true' : 'false');
          // Payment exempt: admin, lawyer, or manually-added users
          final isPaymentExempt = user?['is_payment_exempt'] == true;
          await _storage.write(key: 'veto_payment_exempt', value: isPaymentExempt ? 'true' : 'false');
        }
        return {'success': true, 'user': user};
      }
      if (response.statusCode == 403) {
        final body = jsonDecode(response.body);
        if (body['pending_approval'] == true) {
          return {'pending_approval': true};
        }
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

  /// Authenticate via Google ID token. Returns the same shape as [verifyOTP].
  Future<Map<String, dynamic>?> googleAuth({
    required String idToken,
    String language = 'he',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/google'),
        headers: AppConfig.httpHeaders({}),
        body: jsonEncode({'id_token': idToken, 'preferred_language': language}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'];
        final user  = data['user'];
        final role  = user?['role']?.toString() ?? 'user';
        final name  = user?['full_name']?.toString() ?? '';
        final preferredLanguage = user?['preferred_language']?.toString() ?? language;
        if (token != null) {
          await _storage.write(key: 'jwt', value: token);
          await _storage.write(key: 'veto_role', value: role);
          if (name.isNotEmpty) await _storage.write(key: 'veto_name', value: name);
          await _storage.write(key: 'veto_language', value: preferredLanguage);
          final isSubscribed = user?['is_subscribed'] == true;
          await _storage.write(key: 'veto_subscribed', value: isSubscribed ? 'true' : 'false');
          final isPaymentExempt = user?['is_payment_exempt'] == true;
          await _storage.write(key: 'veto_payment_exempt', value: isPaymentExempt ? 'true' : 'false');
        }
        return {'success': true, 'user': user};
      }
      debugPrint('googleAuth error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('googleAuth error: $e');
      return null;
    }
  }

  Future<String?> getToken() async => await _storage.read(key: 'jwt');
  Future<String?> getStoredRole() async => await _storage.read(key: 'veto_role');
  Future<String?> getStoredName() async => await _storage.read(key: 'veto_name');
  Future<String?> getStoredPhone() async => await _storage.read(key: 'veto_phone');
  Future<String?> getStoredPreferredLanguage() async =>
      await _storage.read(key: 'veto_language');
  Future<void> setStoredPreferredLanguage(String value) async {
    await _storage.write(key: 'veto_language', value: value);
  }
  Future<bool> getStoredIsSubscribed() async {
    final val = await _storage.read(key: 'veto_subscribed');
    return val == 'true';
  }
  Future<void> setSubscribed(bool value) async {
    await _storage.write(key: 'veto_subscribed', value: value ? 'true' : 'false');
  }
  Future<bool> getStoredIsPaymentExempt() async {
    final role = await getStoredRole();
    if (role == 'admin' || role == 'lawyer') return true;
    final val = await _storage.read(key: 'veto_payment_exempt');
    return val == 'true';
  }

  /// Updates full_name on the server and in local storage.
  Future<bool> updateProfile({String? fullName, String? preferredLanguage}) async {
    try {
      final token = await getToken();
      final role = await getStoredRole();
      final baseUrl = AppConfig.baseUrl;
      if (fullName == null && preferredLanguage == null) return false;
      // lawyers use /lawyers/me, users & admins use /users/me
      final endpoint = role == 'lawyer' ? '$baseUrl/lawyers/me' : '$baseUrl/users/me';
      final payload = <String, dynamic>{};
      if (fullName != null) payload['full_name'] = fullName;
      if (preferredLanguage != null) {
        payload['preferred_language'] = preferredLanguage;
      }
      final response = await http.put(
        Uri.parse(endpoint),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        if (fullName != null) {
          await _storage.write(key: 'veto_name', value: fullName);
        }
        if (preferredLanguage != null) {
          await _storage.write(key: 'veto_language', value: preferredLanguage);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    final language = await getStoredPreferredLanguage();
    await _storage.deleteAll();
    if (language != null && language.isNotEmpty) {
      await _storage.write(key: 'veto_language', value: language);
    }
    Navigator.of(context).pushReplacementNamed('/login');
  }
}