// ============================================================
//  citizen_dashboard_api_service.dart — /api/citizen-dashboard/*
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class CitizenDashboardApiService {
  CitizenDashboardApiService._();
  static final CitizenDashboardApiService instance = CitizenDashboardApiService._();

  Future<String?> _tok() => AuthService().getToken();

  Future<Map<String, String>> _headers() async {
    final t = await _tok();
    if (t == null || t.isEmpty) return AppConfig.httpHeaders({});
    return AppConfig.httpHeaders({'Authorization': 'Bearer $t'});
  }

  Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}/citizen-dashboard$path');

  Future<Map<String, dynamic>> fetchSummary() async {
    final res = await http.get(_u('/summary'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('summary ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReportsSummary() async {
    final res =
        await http.get(_u('/reports/summary'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('reports ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listContracts() async {
    final res = await http.get(_u('/contracts'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('contracts ${res.statusCode}');
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createContract(Map<String, dynamic> body) async {
    final res = await http
        .post(_u('/contracts'), headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 201) throw Exception('create contract ${res.statusCode} ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateContract(String id, Map<String, dynamic> body) async {
    final res = await http
        .patch(_u('/contracts/$id'), headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('patch contract ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteContract(String id) async {
    final res =
        await http.delete(_u('/contracts/$id'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('delete contract ${res.statusCode}');
  }

  Future<List<dynamic>> listTasks() async {
    final res = await http.get(_u('/tasks'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('tasks ${res.statusCode}');
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> body) async {
    final res = await http
        .post(_u('/tasks'), headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 201) throw Exception('create task ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> body) async {
    final res = await http
        .patch(_u('/tasks/$id'), headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('patch task ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteTask(String id) async {
    final res = await http.delete(_u('/tasks/$id'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('delete task ${res.statusCode}');
  }

  Future<List<dynamic>> listContacts() async {
    final res = await http.get(_u('/contacts'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('contacts ${res.statusCode}');
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createContact(Map<String, dynamic> body) async {
    final res = await http
        .post(_u('/contacts'), headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 201) throw Exception('create contact ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateContact(String id, Map<String, dynamic> body) async {
    final res = await http
        .patch(_u('/contacts/$id'), headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('patch contact ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteContact(String id) async {
    final res =
        await http.delete(_u('/contacts/$id'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('delete contact ${res.statusCode}');
  }

  Future<List<dynamic>> listNotifications() async {
    final res =
        await http.get(_u('/notifications'), headers: await _headers()).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('notifications ${res.statusCode}');
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<void> markNotificationRead(String id) async {
    final res = await http
        .patch(_u('/notifications/$id/read'), headers: await _headers(), body: '{}')
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('read notif ${res.statusCode}');
  }
}
