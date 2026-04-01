import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

/// Service for handling authentication operations
class AuthService {
  /// Request OTP for phone number
  /// 
  /// Parameters:
  ///   - phoneNumber: The phone number to request OTP for (e.g., +972525640021)
  /// 
  /// Returns the response from the server
  static Future<http.Response> requestOtp(String phoneNumber) async {
    final url = Uri.parse('${AppConfig.baseUrl}/auth/request-otp');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phoneNumber,
        }),
      ).timeout(
        const Duration(seconds: AppConfig.requestTimeoutSeconds),
      );

      return response;
    } catch (e) {
      throw Exception('Failed to request OTP: $e');
    }
  }

  /// Verify OTP code
  /// 
  /// Parameters:
  ///   - phoneNumber: The phone number that requested OTP
  ///   - otpCode: The OTP code to verify
  static Future<http.Response> verifyOtp(
    String phoneNumber,
    String otpCode,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/auth/verify-otp');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phoneNumber,
          'otp': otpCode,
        }),
      ).timeout(
        const Duration(seconds: AppConfig.requestTimeoutSeconds),
      );

      return response;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Register a new account
  /// 
  /// Parameters:
  ///   - fullName: User's full name
  ///   - phoneNumber: User's phone number
  ///   - role: 'user' or 'lawyer'
  static Future<http.Response> register({
    required String fullName,
    required String phoneNumber,
    String role = 'user',
    String language = 'he',
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'phone': phoneNumber,
          'role': role,
          'preferred_language': language,
        }),
      ).timeout(
        const Duration(seconds: AppConfig.requestTimeoutSeconds),
      );

      return response;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }
}
