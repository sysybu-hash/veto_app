// ============================================================
//  fcm_user_service — register FCM token with VETO API (iOS/Android)
// ============================================================

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../firebase_options.dart';
import 'auth_service.dart';

/// Call after login on mobile (not web — use Web Push for browsers).
Future<void> registerFcmIfAvailable() async {
  if (kIsWeb) return;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseMessaging.instance.requestPermission();
    final t = await FirebaseMessaging.instance.getToken();
    if (t == null || t.isEmpty) return;
    final jwt = await AuthService().getToken();
    if (jwt == null) return;
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/fcm-token'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $jwt'}),
      body: jsonEncode({'token': t}),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      debugPrint('[FCM] token registered with API');
    }
  } catch (e) {
    debugPrint('[FCM] register skipped: $e');
  }
}
