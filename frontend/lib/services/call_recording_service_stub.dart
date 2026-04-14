import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_recording_service.dart';

class _UnsupportedCallRecordingService implements CallRecordingService {
  @override
  bool get isSupported => false;

  @override
  Future<void> start({
    required MediaStream? localStream,
    required MediaStream? remoteStream,
    required bool video,
  }) async {}

  @override
  Future<CallRecordingResult?> stop() async => null;
}

CallRecordingService createCallRecordingServiceImpl() =>
    _UnsupportedCallRecordingService();
