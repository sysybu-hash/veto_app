// ============================================================
//  payment_service.dart
//  VETO Legal Emergency App — PayPal payment integration
//
//  Flow:
//    1. Call createOrder(type) → get orderId + approveUrl
//    2. Open approveUrl in new browser tab (dart:html window.open)
//    3. User completes PayPal flow in that tab
//    4. User returns to VETO tab and taps "שילמתי"
//    5. Call captureOrder(orderId, type, userId) → confirm payment
// ============================================================

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

enum PaymentType { subscription, consultation }

class PaymentResult {
  final bool success;
  final String? captureId;
  final String? error;
  const PaymentResult({required this.success, this.captureId, this.error});
}

class PaymentService {
  static String get _base => '${AppConfig.baseUrl}/payments';

  // ── Step 1: create PayPal order, open approval URL ─────────
  /// Returns the orderId (needed for capture step).
  /// Opens PayPal in a new browser tab automatically.
  static Future<String?> createAndOpenOrder(PaymentType type) async {
    final endpoint = type == PaymentType.subscription
        ? '$_base/subscription'
        : '$_base/consultation';

    try {
      final res = await http.post(Uri.parse(endpoint));
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final orderId = body['orderId'] as String?;
      final approveUrl = body['approveUrl'] as String?;

      if (approveUrl != null) {
        // Open PayPal in a new tab — user pays there, then comes back
        html.window.open(approveUrl, '_blank');
      }

      return orderId;
    } catch (_) {
      return null;
    }
  }

  // ── Step 2: capture order after user confirms payment ──────
  static Future<PaymentResult> captureOrder({
    required String orderId,
    required PaymentType type,
    String? userId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/capture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'type': type == PaymentType.subscription ? 'subscription' : 'consultation',
          if (userId != null) 'userId': userId,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        return PaymentResult(success: true, captureId: body['captureId'] as String?);
      }
      return PaymentResult(success: false, error: body['error'] as String?);
    } catch (e) {
      return PaymentResult(success: false, error: e.toString());
    }
  }
}
