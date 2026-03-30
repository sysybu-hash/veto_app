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
          'phoneNumber': phoneNumber,
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
          'phoneNumber': phoneNumber,
          'otpCode': otpCode,
        }),
      ).timeout(
        const Duration(seconds: AppConfig.requestTimeoutSeconds),
      );

      return response;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }
}
