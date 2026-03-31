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

  void connect() async {
    final token = await _storage.read(key: 'jwt') ?? await _storage.read(key: 'veto_token');
    if (token == null) {
      debugPrint('SocketService: No JWT or VETO_TOKEN found, cannot connect to socket.');
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('SocketService: Already connected.');
      return;
    }

    final Map<String, String> extraHeaders = AppConfig.httpHeadersBinary();
    
    _socket = IO.io(AppConfig.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .disableAutoConnect()
            .setExtraHeaders({'x-auth-token': token, ...extraHeaders})
            .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('SocketService: Connected');
    });

    _socket!.onDisconnect((_) {
      debugPrint('SocketService: Disconnected');
    });

    _socket!.on('error', (data) {
      debugPrint('SocketService: Error: $data');
    });

    _socket!.on('vetoStarted', (data) {
      debugPrint('SocketService: VETO Started event received: $data');
      if (data != null && data['eventId'] != null) {
        currentEventId = data['eventId'];
      }
    });
  }

  void emitStartVeto(Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('startVeto', data);
      debugPrint('SocketService: Emitted startVeto with data: $data');
    } else {
      debugPrint('SocketService: Socket not connected, cannot emit startVeto.');
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

  void disconnect() {
    _socket?.disconnect();
    debugPrint('SocketService: Disconnected explicitly.');
  }
}
