// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../../services/call_recording_types.dart';
import 'browser_mic_call_recorder_api.dart';

BrowserMicCallRecorder createBrowserMicCallRecorder() => _WebBrowserMic();

class _WebBrowserMic implements BrowserMicCallRecorder {
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = <html.Blob>[];
  bool _starting = false;
  bool _started = false;
  String _eventId = '';

  String _pickMime() {
    const candidates = <String>[
      'audio/webm;codecs=opus',
      'audio/webm',
    ];
    for (final c in candidates) {
      if (html.MediaRecorder.isTypeSupported(c)) return c;
    }
    return 'audio/webm';
  }

  @override
  Future<void> start({required String eventId}) async {
    if (_starting || _started) return;
    _starting = true;
    _eventId = eventId;
    try {
      _stream = await html.window.navigator.mediaDevices!.getUserMedia(
        {'audio': true},
      );
      final mime = _pickMime();
      _recorder = html.MediaRecorder(_stream!, {'mimeType': mime});
      _chunks.clear();
      _recorder!.addEventListener('dataavailable', (html.Event e) {
        final be = e as html.BlobEvent;
        final b = be.data;
        if (b != null && b.size > 0) {
          _chunks.add(b);
        }
      });
      _recorder!.start(900);
      _started = true;
    } catch (_) {
      _cleanupTracks();
      _stream = null;
      _recorder = null;
    } finally {
      _starting = false;
    }
  }

  void _cleanupTracks() {
    final s = _stream;
    if (s == null) return;
    for (final t in s.getTracks()) {
      try {
        t.stop();
      } catch (_) {}
    }
  }

  @override
  Future<CallRecordingResult?> stop() async {
    final rec = _recorder;
    _recorder = null;
    if (rec == null || !_started) {
      _cleanupTracks();
      _stream = null;
      _started = false;
      return null;
    }
    _started = false;

    final done = Completer<void>();
    void onStopOnce(html.Event _) {
      if (!done.isCompleted) done.complete();
    }

    rec.addEventListener('stop', onStopOnce);
    try {
      rec.stop();
    } catch (_) {}

    await done.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        if (!done.isCompleted) done.complete();
      },
    );
    rec.removeEventListener('stop', onStopOnce);

    _cleanupTracks();
    _stream = null;

    if (_chunks.isEmpty) return null;
    final blob = html.Blob(_chunks);
    _chunks.clear();

    final reader = html.FileReader();
    final bytesCompleter = Completer<ByteBuffer?>();
    reader.onLoad.listen((_) {
      final r = reader.result;
      if (r is ByteBuffer) {
        bytesCompleter.complete(r);
      } else if (r is Uint8List) {
        bytesCompleter.complete(r.buffer);
      } else {
        bytesCompleter.complete(null);
      }
    });
    reader.onError.listen((_) {
      if (!bytesCompleter.isCompleted) bytesCompleter.complete(null);
    });
    reader.readAsArrayBuffer(blob);
    final buf = await bytesCompleter.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => null,
    );
    if (buf == null) return null;
    final bytes = Uint8List.view(buf);
    if (bytes.isEmpty) return null;
    final id = _eventId.isNotEmpty ? _eventId : 'call';
    return CallRecordingResult(
      bytes: bytes,
      mimeType: 'audio/webm',
      fileName: 'veto-call-$id-mic.webm',
    );
  }
}
