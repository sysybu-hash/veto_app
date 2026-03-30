// ============================================================
//  socket_service.dart — Socket.io Client Wrapper
//  VETO Legal Emergency App
//  Singleton service; call SocketService() from anywhere.
// ============================================================

import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../config/app_config.dart';

class SocketService {
  // ── Singleton ──────────────────────────────────────────────
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // ── Stream controllers (broadcast = multiple listeners) ───
  final _emergencyAlertCtrl  = StreamController<Map<String, dynamic>>.broadcast();
  final _lawyerFoundCtrl     = StreamController<Map<String, dynamic>>.broadcast();
  final _caseTakenCtrl       = StreamController<Map<String, dynamic>>.broadcast();
  final _caseConfirmedCtrl   = StreamController<Map<String, dynamic>>.broadcast();
  final _vetoDispatchedCtrl  = StreamController<Map<String, dynamic>>.broadcast();
  final _noLawyersCtrl       = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionCtrl      = StreamController<bool>.broadcast();

  // ── Public streams ─────────────────────────────────────────
  Stream<Map<String, dynamic>> get onEmergencyAlert  => _emergencyAlertCtrl.stream;
  Stream<Map<String, dynamic>> get onLawyerFound     => _lawyerFoundCtrl.stream;
  Stream<Map<String, dynamic>> get onCaseTaken       => _caseTakenCtrl.stream;
  Stream<Map<String, dynamic>> get onCaseConfirmed   => _caseConfirmedCtrl.stream;
  Stream<Map<String, dynamic>> get onVetoDispatched  => _vetoDispatchedCtrl.stream;
  Stream<Map<String, dynamic>> get onNoLawyers       => _noLawyersCtrl.stream;
  Stream<bool>                 get onConnectionChange => _connectionCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  // ── Connect ────────────────────────────────────────────────
  void connect({required String serverUrl, required String token}) {
    if (_socket != null && _socket!.connected) return;

    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect();
    if (serverUrl.contains('loca.lt')) {
      opts.setExtraHeaders({...AppConfig.kTunnelBypassHeaders});
    }
    _socket = IO.io(serverUrl, opts.build());

    _socket!.connect();

    // ── Connection events ──────────────────────────────────
    _socket!.onConnect((_) {
      print('✅ Socket connected: ${_socket!.id}');
      _connectionCtrl.add(true);
    });

    _socket!.onDisconnect((_) {
      print('🔌 Socket disconnected');
      _connectionCtrl.add(false);
    });

    _socket!.onConnectError((err) {
      print('❌ Socket connect error: $err');
      _connectionCtrl.add(false);
    });

    // ── Lawyer-facing events ───────────────────────────────
    _socket!.on('new_emergency_alert', (data) {
      _emergencyAlertCtrl.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('case_taken', (data) {
      _caseTakenCtrl.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('case_accepted_confirmed', (data) {
      _caseConfirmedCtrl.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('case_already_taken', (data) {
      _caseTakenCtrl.add(Map<String, dynamic>.from(data));
    });

    // ── User-facing events ─────────────────────────────────
    _socket!.on('lawyer_found', (data) {
      _lawyerFoundCtrl.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('veto_dispatched', (data) {
      _vetoDispatchedCtrl.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('no_lawyers_available', (data) {
      _noLawyersCtrl.add(Map<String, dynamic>.from(data));
    });
  }

  // ── Emit helpers ───────────────────────────────────────────
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void acceptCase(String eventId) =>
      emit('accept_case', {'eventId': eventId});

  void rejectCase(String eventId) =>
      emit('reject_case', {'eventId': eventId});

  void startVeto({
    required double lat,
    required double lng,
    required String preferredLanguage,
  }) {
    emit('start_veto', {
      'location': {'lat': lat, 'lng': lng},
      'preferredLanguage': preferredLanguage,
    });
  }

  void cancelVeto(String eventId) =>
      emit('cancel_veto', {'eventId': eventId});

  // ── Disconnect ─────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _emergencyAlertCtrl.close();
    _lawyerFoundCtrl.close();
    _caseTakenCtrl.close();
    _caseConfirmedCtrl.close();
    _vetoDispatchedCtrl.close();
    _noLawyersCtrl.close();
    _connectionCtrl.close();
  }
}
