// Optional local mixed capture was removed; post-call media comes from Agora MediaRecorder
// on iOS/Android (see [CallSessionController]). Web has no file capture yet.
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
