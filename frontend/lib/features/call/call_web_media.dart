import 'package:flutter/foundation.dart';

/// Web camera/mic require a [secure context](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts).
bool isCallMediaSecureContext() {
  if (!kIsWeb) return true;
  final u = Uri.base;
  if (u.scheme == 'https') return true;
  final h = u.host.toLowerCase();
  if (h == 'localhost' || h == '127.0.0.1' || h == '[::1]') return true;
  return false;
}
