import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class SocketService {
  IO.Socket? _socket;
  static String? currentEventId;
  final _storage = const FlutterSecureStorage();

  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  // ── Streams for UI to listen to ───────────────────────────────
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionChange => _connectionController.stream;

  final _emergencyAlertController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onEmergencyAlert => _emergencyAlertController.stream;

  final _emergencyCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onEmergencyCreated => _emergencyCreatedController.stream;

  final _caseTakenController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCaseTaken => _caseTakenController.stream;

  final _caseConfirmedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCaseConfirmed => _caseConfirmedController.stream;

  void connect({String? serverUrl, String? token}) async {
    final authToken = token ?? await _storage.read(key: 'jwt') ?? await _storage.read(key: 'veto_token');
    if (authToken == null) {
      debugPrint('SocketService: No JWT or VETO_TOKEN found, cannot connect to socket.');
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('SocketService: Already connected.');
      return;
    }

    final Map<String, String> extraHeaders = AppConfig.httpHeadersBinary({});
    
    final url = serverUrl ?? AppConfig.socketOrigin;

    _socket = IO.io(url,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .disableAutoConnect()
            .setExtraHeaders({'x-auth-token': authToken, ...extraHeaders})
            .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('SocketService: Connected');
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('SocketService: Disconnected');
      _connectionController.add(false);
    });

    _socket!.on('error', (data) {
      debugPrint('SocketService: Error: $data');
    });

    // ── Client events ──
    _socket!.on('emergency_created', (data) {
      debugPrint('SocketService: emergency_created event received: $data');
      if (data != null && data['eventId'] != null) {
        currentEventId = data['eventId'];
        if (data is Map<String, dynamic>) {
          _emergencyCreatedController.add(data);
        }
      }
    });

    _socket!.on('veto_dispatched', (data) {
      debugPrint('SocketService: VETO Dispatched event received: $data');
    });

    // ── Lawyer events ──
    _socket!.on('emergency_alert', (data) {
      debugPrint('SocketService: Emergency alert received: $data');
      if (data is Map<String, dynamic>) {
        _emergencyAlertController.add(data);
      }
    });

    _socket!.on('case_taken_by_other', (data) {
      debugPrint('SocketService: Case taken by other: $data');
      if (data is Map<String, dynamic>) {
        _caseTakenController.add(data);
      }
    });

    _socket!.on('case_accepted_confirmed', (data) {
      debugPrint('SocketService: Case accepted confirmed: $data');
      if (data is Map<String, dynamic>) {
        _caseConfirmedController.add(data);
      }
    });
  }

  // ── Client Actions ───────────────────────────────────────────
  void emitStartVeto({required double lat, required double lng, String? preferredLanguage}) {
    if (_socket != null && _socket!.connected) {
      final data = {
        'location': {'lat': lat, 'lng': lng},
        'preferredLanguage': preferredLanguage ?? 'en',
      };
      _socket!.emit('start_veto', data);
      debugPrint('SocketService: Emitted start_veto with data: $data');
    } else {
      debugPrint('SocketService: Socket not connected, cannot emit start_veto.');
    }
  }

  void emitEvidence(Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('evidence', data);
      debugPrint('SocketService: Emitted evidence with data: $data');
    } else {
      debugPrint('SocketService: Socket not connected, cannot emit evidence.');
    }
  }

  // ── Lawyer Actions ───────────────────────────────────────────
  void acceptCase(String eventId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('accept_case', {'eventId': eventId});
      debugPrint('SocketService: Emitted accept_case for eventId: $eventId');
    } else {
      debugPrint('SocketService: Socket not connected, cannot accept case.');
    }
  }

  void rejectCase(String eventId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('reject_case', {'eventId': eventId});
      debugPrint('SocketService: Emitted reject_case for eventId: $eventId');
    } else {
      debugPrint('SocketService: Socket not connected, cannot reject case.');
    }
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
      debugPrint('SocketService: Emitted $event with data: $data');
    } else {
      debugPrint('SocketService: Socket not connected, cannot emit $event.');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    debugPrint('SocketService: Disconnected explicitly.');
  }
}
