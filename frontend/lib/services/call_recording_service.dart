import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_recording_service_stub.dart'
    if (dart.library.html) 'call_recording_service_web.dart';

class CallRecordingResult {
  const CallRecordingResult({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileName;
}

abstract class CallRecordingService {
  bool get isSupported;

  Future<void> start({
    required MediaStream? localStream,
    required MediaStream? remoteStream,
    required bool video,
  });

  Future<CallRecordingResult?> stop();
}

CallRecordingService createCallRecordingService() =>
    createCallRecordingServiceImpl();
