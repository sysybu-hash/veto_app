import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../config/app_config.dart';
import 'auth_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  socket_io.Socket? _socket;
  String? _connectedRole;
  Completer<void>? _connectCompleter;
  final List<Map<String, dynamic>> _pendingEmits = <Map<String, dynamic>>[];
  final Map<String, List<Function(dynamic)>> _dynamicHandlers =
      <String, List<Function(dynamic)>>{};

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
  final _caseTakenController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _vetoErrorController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _caseAlreadyTakenController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _sessionReadyController =
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
  Stream<Map<String, dynamic>> get onCaseTaken =>
      _caseTakenController.stream;
  Stream<Map<String, dynamic>> get onVetoError =>
      _vetoErrorController.stream;
  Stream<Map<String, dynamic>> get onCaseAlreadyTaken =>
      _caseAlreadyTakenController.stream;
  Stream<Map<String, dynamic>> get onSessionReady =>
      _sessionReadyController.stream;

  SocketService._internal();

  Future<void> connect({String role = 'user'}) async {
    final token = await AuthService().getToken();
    if (token == null) {
      debugPrint('SocketService: No token, cannot connect.');
      return;
    }

    if ((_socket?.connected ?? false) && _connectedRole == role) {
      debugPrint('SocketService: Already connected as $role.');
      return;
    }

    if (_socket != null && _connectedRole != role) {
      debugPrint(
        'SocketService: Reconnecting with new role. old=$_connectedRole new=$role',
      );
      disconnect();
    }

    if (_socket != null &&
        !(_socket?.connected ?? false) &&
        _connectCompleter != null &&
        !(_connectCompleter?.isCompleted ?? true)) {
      try {
        await _connectCompleter!.future.timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('SocketService: Existing connect attempt failed: $e');
      }
      return;
    }

    _socket?.dispose();

    debugPrint('SocketService: Connecting to ${AppConfig.socketOrigin} with role $role');
    _socket = socket_io.io(AppConfig.socketOrigin, <String, dynamic>{
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
    _connectedRole = role;
    _connectCompleter = Completer<void>();

    _socket?.onConnect((_) {
      debugPrint('Socket connected (Role: $role) - Socket ID: ${_socket?.id}');
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.complete();
      }
      _flushPendingEmits();
    });

    _socket?.onConnectError((err) {
      debugPrint('Socket connect error: $err');
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.completeError(err ?? 'connect_error');
      }
    });

    _socket?.on('emergency_created', (d) => _emit(_emergencyCreatedController, d));
    // Backend emits `new_emergency_alert`; also fan-in to onEmergencyAlert for legacy listeners.
    _socket?.on('new_emergency_alert', (d) {
      _emit(_newEmergencyAlertController, d);
      _emit(_emergencyAlertController, d);
    });
    _socket?.on('emergency_alert', (d) => _emit(_emergencyAlertController, d));
    _socket?.on('case_accepted', (d) => _emit(_caseAcceptedController, d));
    _socket?.on(
      'case_accepted_confirmed',
      (d) => _emit(_caseAcceptedController, d),
    );
    _socket?.on('veto_dispatched', (d) => _emit(_vetoDispatchedController, d));
    _socket?.on('lawyer_found', (d) => _emit(_lawyerFoundController, d));
    _socket?.on(
      'no_lawyers_available',
      (d) => _emit(_noLawyersController, d),
    );
    _socket?.on('case_taken', (d) => _emit(_caseTakenController, d));
    _socket?.on('veto_error', (d) => _emit(_vetoErrorController, d));
    _socket?.on(
      'case_already_taken',
      (d) => _emit(_caseAlreadyTakenController, d),
    );
    _socket?.on('session_ready', (d) => _emit(_sessionReadyController, d));

    _socket?.onDisconnect((_) {
      debugPrint('Socket disconnected');
      if (_connectCompleter != null && !(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.completeError('disconnect');
      }
    });

    _socket?.onError((err) {
      debugPrint('Socket Error: $err');
    });

    _attachDynamicHandlers();
    _socket?.connect();

    try {
      await _connectCompleter!.future.timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('SocketService: connect() did not complete successfully: $e');
    }
  }

  void emit(String event, dynamic data) {
    debugPrint('SocketService: Emitting event "$event" with data: $data');
    final socket = _socket;
    if (socket == null || !socket.connected) {
      _pendingEmits.add({'event': event, 'data': data});
      // Do not call socket.connect() here: on Flutter Web, redundant opens while the
      // engine is closing the WebSocket spam "already in CLOSING or CLOSED" errors.
      // Reconnection is handled by socket.io (reconnection: true); pending emits flush onConnect.
      if (socket == null) {
        debugPrint(
          'SocketService.emit: no socket — call connect(role:) before emitting "$event".',
        );
      }
      return;
    }
    socket.emit(event, data);
  }

  /// Returns whether the socket is connected after [connect] completes (same role).
  Future<bool> ensureConnected({required String role}) async {
    await connect(role: role);
    return isConnected;
  }

  /// Register a dynamic listener for any socket event.
  /// Used by WebRTCService and call screens for WebRTC signaling events.
  void on(String event, Function(dynamic) handler) {
    _dynamicHandlers.putIfAbsent(event, () => <Function(dynamic)>[]).add(handler);
    _socket?.on(event, (data) => _handleDynamicEvent(event, data));
  }

  /// Remove a dynamic listener.
  void off(String event) {
    _dynamicHandlers.remove(event);
    _socket?.off(event);
  }

  /// Remove one handler without dropping other listeners for the same event (e.g. WebRTC + CallScreen).
  void removeHandler(String event, Function(dynamic) handler) {
    final list = _dynamicHandlers[event];
    if (list == null) return;
    list.remove(handler);
    if (list.isEmpty) {
      _dynamicHandlers.remove(event);
      _socket?.off(event);
    }
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

  void emitCitizenChoseSession({
    required String eventId,
    required String callType,
  }) {
    emit('citizen_chose_session', {
      'eventId': eventId,
      'callType': callType,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectedRole = null;
    _connectCompleter = null;
  }

  void _flushPendingEmits() {
    final socket = _socket;
    if (socket == null || !socket.connected || _pendingEmits.isEmpty) return;
    final pending = List<Map<String, dynamic>>.from(_pendingEmits);
    _pendingEmits.clear();
    for (final item in pending) {
      socket.emit(item['event'] as String, item['data']);
    }
  }

  void _attachDynamicHandlers() {
    if (_socket == null) return;
    for (final entry in _dynamicHandlers.entries) {
      _socket!.on(entry.key, (data) => _handleDynamicEvent(entry.key, data));
    }
  }

  void _handleDynamicEvent(String event, dynamic data) {
    final handlers = _dynamicHandlers[event];
    if (handlers == null || handlers.isEmpty) return;
    dynamic parsed = data;
    if (data is List && data.isNotEmpty) parsed = data.first;
    if (parsed is Map) parsed = Map<String, dynamic>.from(parsed);
    for (final handler in List<Function(dynamic)>.from(handlers)) {
      handler(parsed);
    }
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
