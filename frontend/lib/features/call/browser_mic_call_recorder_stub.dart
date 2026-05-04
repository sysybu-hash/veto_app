import '../../services/call_recording_types.dart';
import 'browser_mic_call_recorder_api.dart';

BrowserMicCallRecorder createBrowserMicCallRecorder() => _StubBrowserMic();

class _StubBrowserMic implements BrowserMicCallRecorder {
  @override
  Future<void> start({required String eventId}) async {}

  @override
  Future<CallRecordingResult?> stop() async => null;
}
