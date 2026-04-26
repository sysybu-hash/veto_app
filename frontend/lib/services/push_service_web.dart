// ============================================================
//  push_service_web.dart — Web Push (browser only)
// ============================================================

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

class PushService {
  static final PushService _i = PushService._();
  factory PushService() => _i;
  PushService._();

  Future<void> registerLawyerPush() async {
    if (!kIsWeb) return;
    try {
      final keyRes = await http.get(
        Uri.parse('${AppConfig.baseUrl}/push/vapid-key'),
        headers: AppConfig.httpHeaders({}),
      );
      if (keyRes.statusCode != 200) return;
      final vapidKey = (jsonDecode(keyRes.body) as Map)['publicKey'] as String?;
      if (vapidKey == null || vapidKey.isEmpty) return;

      final pushRaw = window['vetoPushSubscribe'];
      if (!pushRaw.isA<JSFunction>()) return;
      final pushFn = pushRaw as JSFunction;
      final raw = pushFn.callAsFunction(null, vapidKey.toJS);
      final promise = raw as JSPromise<JSAny?>;
      final result = await promise.toDart;
      if (result == null) return;

      final jsonObj = window['JSON'];
      final jsonStr =
          jsonObj.callMethod<JSString>('stringify'.toJS, result).toDart;
      final Map<String, dynamic> subscription;
      try {
        subscription =
            Map<String, dynamic>.from(jsonDecode(jsonStr) as Map<dynamic, dynamic>);
      } catch (_) {
        return;
      }

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
