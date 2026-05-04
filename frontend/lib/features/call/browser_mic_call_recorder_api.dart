import '../../services/call_recording_types.dart';

/// Browser-only mic capture for post-call vault (WebRTC / Agora does not expose mixed PCM in Flutter web).
abstract class BrowserMicCallRecorder {
  /// [eventId] is used for the suggested vault filename on web.
  Future<void> start({required String eventId});

  /// Stops capture and returns WebM/Opus bytes, or null if nothing was recorded.
  Future<CallRecordingResult?> stop();
}
