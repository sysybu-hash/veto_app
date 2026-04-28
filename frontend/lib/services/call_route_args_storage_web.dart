// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

const _k = 'veto_call_route_args_v1';

void callRouteArgsStorageWrite(Map<String, dynamic> args) {
  html.window.sessionStorage[_k] = jsonEncode({
    ...args,
    '_vetoSavedAt': DateTime.now().millisecondsSinceEpoch,
  });
}

Map<String, dynamic>? callRouteArgsStorageRead() {
  final raw = html.window.sessionStorage[_k];
  if (raw == null || raw.isEmpty) return null;
  return _parseAndValidate(raw);
}

void callRouteArgsStorageClear() {
  html.window.sessionStorage.remove(_k);
}

Map<String, dynamic>? _parseAndValidate(String raw) {
  try {
    final o = jsonDecode(raw);
    if (o is! Map) return null;
    final m = Map<String, dynamic>.from(
      o.map((k, v) => MapEntry(k.toString(), v)),
    );
    final t = m['_vetoSavedAt'];
    m.remove('_vetoSavedAt');
    if (t is num) {
      final age = DateTime.now().millisecondsSinceEpoch - t.toInt();
      if (age > const Duration(hours: 3).inMilliseconds) {
        return null;
      }
    }
    return m;
  } catch (_) {
    return null;
  }
}
