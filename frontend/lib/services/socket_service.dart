import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';
import 'auth_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  IO.Socket? _socket;

  final _emergencyCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyAlertController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _caseAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _vetoDispatchedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _newEmergencyAlertController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _lawyerFoundController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _noLawyersController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onEmergencyCreated =>
      _emergencyCreatedController.stream;
  Stream<Map<String, dynamic>> get onEmergencyAlert =>
      _emergencyAlertController.stream;
  Stream<Map<String, dynamic>> get onCaseAccepted =>
      _caseAcceptedController.stream;
  Stream<Map<String, dynamic>> get onVetoDispatched =>
      _vetoDispatchedController.stream;
  Stream<Map<String, dynamic>> get onNewEmergencyAlert =>
      _newEmergencyAlertController.stream;
  Stream<Map<String, dynamic>> get onLawyerFound =>
      _lawyerFoundController.stream;
  Stream<Map<String, dynamic>> get onNoLawyersAvailable =>
      _noLawyersController.stream;

  SocketService._internal();

  Future<void> connect({String role = 'user'}) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    if (_socket?.connected ?? false) return;

    _socket?.dispose();

    _socket = IO.io(AppConfig.socketOrigin, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'auth': {'token': token},
      'query': {'role': role},
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 10000,
      'timeout': 20000,
    });

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('Socket connected (Role: $role)');
    });

    _socket?.on('emergency_created', (data) {
      if (data is Map<String, dynamic>) {
        _emergencyCreatedController.add(data);
      }
    });

    _socket?.on('emergency_alert', (data) {
      if (data is Map<String, dynamic>) {
        _emergencyAlertController.add(data);
      }
    });

    _socket?.on('new_emergency_alert', (data) {
      if (data is Map<String, dynamic>) {
        _newEmergencyAlertController.add(data);
      }
    });

    _socket?.on('case_accepted', (data) {
      if (data is Map<String, dynamic>) {
        _caseAcceptedController.add(data);
      }
    });

    _socket?.on('veto_dispatched', (data) {
      if (data is Map<String, dynamic>) {
        _vetoDispatchedController.add(data);
      }
    });

    _socket?.on('lawyer_found', (data) {
      if (data is Map<String, dynamic>) {
        _lawyerFoundController.add(data);
      }
    });

    _socket?.on('no_lawyers_available', (data) {
      if (data is Map<String, dynamic>) {
        _noLawyersController.add(data);
      }
    });

    _socket?.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });
  }

  void emit(String event, Map<String, dynamic> data) {
    _socket?.emit(event, data);
  }

  void emitStartVeto(
      {required double lat, required double lng, String? preferredLanguage, String? specialization}) {
    final payload = {
      'location': {'lat': lat, 'lng': lng},
      'preferredLanguage': preferredLanguage,
      'details': 'Emergency triggered via VETO AI agent',
    };
    if (specialization != null) payload['specialization'] = specialization;
    emit('start_veto', payload);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
