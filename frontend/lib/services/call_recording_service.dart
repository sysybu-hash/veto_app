// Local call recording: WebRTC path removed. Agora uses server-side recording + transcribe.
// [CallRecordingResult] is still used by [VaultSaveQueue] for optional future client-side blobs.

import 'call_recording_types.dart';

export 'call_recording_types.dart' show CallRecordingResult;

abstract class CallRecordingService {
  bool get isSupported;

  Future<void> start({Object? localStream, Object? remoteStream, required bool video});

  Future<CallRecordingResult?> stop();
}

CallRecordingService createCallRecordingService() => _NoOpCallRecordingService();

class _NoOpCallRecordingService implements CallRecordingService {
  @override
  bool get isSupported => false;

  @override
  Future<void> start({Object? localStream, Object? remoteStream, required bool video}) async {}

  @override
  Future<CallRecordingResult?> stop() async => null;
}
