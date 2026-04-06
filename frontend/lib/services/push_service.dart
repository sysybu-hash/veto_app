// ============================================================
//  push_service.dart — Web Push Subscription Registration
//  VETO Legal Emergency App
//
//  Call registerLawyerPush() once after a lawyer logs in.
//  Requires: web/push-sw.js service worker (already registered in index.html)
// ============================================================

// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class PushService {
  static final PushService _i = PushService._();
  factory PushService() => _i;
  PushService._();

  /// Call once after lawyer login to register browser push subscription.
  Future<void> registerLawyerPush() async {
    if (!kIsWeb) return;
    try {
      // 1. Fetch VAPID public key from backend
      final keyRes = await http.get(
        Uri.parse('${AppConfig.baseUrl}/push/vapid-key'),
        headers: AppConfig.httpHeaders({}),
      );
      if (keyRes.statusCode != 200) return;
      final vapidKey = (jsonDecode(keyRes.body) as Map)['publicKey'] as String?;
      if (vapidKey == null || vapidKey.isEmpty) return;

      // 2. Call JS function exposed in index.html
      final completer = Completer<Map<String, dynamic>?>();
      final jsPromise = js.context.callMethod('vetoPushSubscribe', [vapidKey]);

      (jsPromise as js.JsObject).callMethod('then', [
        (result) {
          if (result == null) {
            completer.complete(null);
          } else {
            try {
              // JsObject → JSON string → Dart Map
              final jsonStr = js.context['JSON'].callMethod('stringify', [result]) as String;
              completer.complete(Map<String, dynamic>.from(jsonDecode(jsonStr) as Map));
            } catch (_) {
              completer.complete(null);
            }
          }
        },
      ]);
      (jsPromise).callMethod('catch', [(e) => completer.complete(null)]);

      final subscription = await completer.future.timeout(const Duration(seconds: 15));
      if (subscription == null) return;

      // 3. POST subscription to backend
      final token = await AuthService().getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('${AppConfig.baseUrl}/lawyers/push-subscription'),
        headers: AppConfig.httpHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode({'subscription': subscription}),
      );
      debugPrint('[PushService] ✅ Push subscription registered');
    } catch (e) {
      debugPrint('[PushService] registration failed (non-fatal): $e');
    }
  }
}

