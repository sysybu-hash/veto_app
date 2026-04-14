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
    if (token == null) {
      debugPrint('SocketService: No token, cannot connect.');
      return;
    }

    if (_socket?.connected ?? false) {
      debugPrint('SocketService: Already connected.');
      return;
    }

    _socket?.dispose();

    debugPrint('SocketService: Connecting to ${AppConfig.socketOrigin} with role $role');
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
      debugPrint('Socket connected (Role: $role) - Socket ID: ${_socket?.id}');
    });

    _socket?.on('emergency_created',     (d) => _emit(_emergencyCreatedController, d));
    _socket?.on('emergency_alert',        (d) => _emit(_emergencyAlertController, d));
    _socket?.on('new_emergency_alert',    (d) => _emit(_newEmergencyAlertController, d));
    _socket?.on('case_accepted',          (d) => _emit(_caseAcceptedController, d));
    _socket?.on('case_accepted_confirmed',(d) => _emit(_caseAcceptedController, d));
    _socket?.on('veto_dispatched',        (d) => _emit(_vetoDispatchedController, d));
    _socket?.on('lawyer_found',           (d) => _emit(_lawyerFoundController, d));
    _socket?.on('no_lawyers_available',   (d) => _emit(_noLawyersController, d));

    _socket?.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket?.onError((err) {
      debugPrint('Socket Error: $err');
    });
  }

  void emit(String event, dynamic data) {
    debugPrint('SocketService: Emitting event "$event" with data: $data');
    _socket?.emit(event, data);
  }

  /// Register a dynamic listener for any socket event.
  /// Used by WebRTCService and call screens for WebRTC signaling events.
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, (data) {
      dynamic parsed = data;
      if (data is List && data.isNotEmpty) parsed = data.first;
      if (parsed is Map) parsed = Map<String, dynamic>.from(parsed as Map);
      handler(parsed);
    });
  }

  /// Remove a dynamic listener.
  void off(String event) {
    _socket?.off(event);
  }

  /// Whether the socket is currently connected.
  bool get isConnected => _socket?.connected ?? false;

  void emitStartVeto({
    required double lat,
    required double lng,
    String? preferredLanguage,
    String? specialization,
    String? callType,
  }) {
    final payload = {
      'location': {'lat': lat, 'lng': lng},
      'preferredLanguage': preferredLanguage,
      'details': 'Emergency triggered via VETO AI agent',
    };
    if (specialization != null) payload['specialization'] = specialization;
    if (callType != null && callType.isNotEmpty) payload['callType'] = callType;
    emit('start_veto', payload);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// socket.io-client for Dart may deliver payloads as:
  ///   Map<dynamic, dynamic>  — most common
  ///   List                   — some versions wrap the object in a list
  /// This helper normalises both before forwarding to the stream.
  static void _emit(StreamController<Map<String, dynamic>> ctrl, dynamic data) {
    Map<String, dynamic>? map;
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
    } else if (data is List && data.isNotEmpty && data.first is Map) {
      map = Map<String, dynamic>.from(data.first as Map);
    }
    if (map != null) ctrl.add(map);
  }
}
