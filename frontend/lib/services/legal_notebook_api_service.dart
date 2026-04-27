// ============================================================
//  /api/legal-notebook
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

class LegalNotebookApiService {
  Future<String?> _t() => AuthService().getToken();

  Future<List<Map<String, dynamic>>> list() async {
    final t = await _t();
    if (t == null) return [];
    final r = await http.get(
      Uri.parse('${AppConfig.baseUrl}/legal-notebook/'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    if (r.statusCode != 200) return [];
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final n = (j['notebooks'] as List<dynamic>?) ?? [];
    return n.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> create() async {
    final t = await _t();
    if (t == null) return;
    await http.post(
      Uri.parse('${AppConfig.baseUrl}/legal-notebook/'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
      body: jsonEncode({}),
    );
  }

  Future<String?> openUrl(String id) async {
    final t = await _t();
    if (t == null) return null;
    final r = await http.get(
      Uri.parse('${AppConfig.baseUrl}/legal-notebook/${Uri.encodeComponent(id)}/open'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return j['url'] as String?;
  }

  Future<void> openInBrowser(String id) async {
    final u = await openUrl(id);
    if (u == null || u.isEmpty) return;
    await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
  }

  Future<Map<String, dynamic>?> sync(String id) async {
    final t = await _t();
    if (t == null) return null;
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/legal-notebook/${Uri.encodeComponent(id)}/sync'),
      headers: AppConfig.httpHeaders({'Authorization': 'Bearer $t'}),
    );
    if (r.statusCode != 200) return null;
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
