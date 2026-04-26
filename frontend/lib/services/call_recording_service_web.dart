import 'dart:async';
import 'dart:js_interop';

import 'package:dart_webrtc/dart_webrtc.dart' show MediaStreamWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'call_recording_service.dart';

const int _kAudioBps = 96000;
const int _kVideoBps = 1200000;
const int _kTimeSliceMs = 1000;

String _pickMime(bool video) {
  if (video) {
    const opts = [
      'video/webm;codecs=vp9,opus',
      'video/webm;codecs=vp8,opus',
      'video/webm',
    ];
    for (final m in opts) {
      if (web.MediaRecorder.isTypeSupported(m)) return m;
    }
    return 'video/webm';
  }
  const opts = ['audio/webm;codecs=opus', 'audio/webm'];
  for (final m in opts) {
    if (web.MediaRecorder.isTypeSupported(m)) return m;
  }
  return 'audio/webm';
}

class _WebCallRecordingService implements CallRecordingService {
  web.MediaRecorder? _rec;
  MediaStream? _recordingStream;
  String _mimeType = 'audio/webm';
  Completer<String>? _urlCompleter;
  final List<web.Blob> _chunks = [];
  var _isVideo = false;

  @override
  bool get isSupported => kIsWeb;

  @override
  Future<void> start({
    required MediaStream? localStream,
    required MediaStream? remoteStream,
    required bool video,
  }) async {
    if (!isSupported || _rec != null) return;
    _isVideo = video;
    _chunks.clear();

    final sourceVideo = remoteStream?.getVideoTracks().isNotEmpty == true
        ? remoteStream
        : localStream;
    final sourceAudio = <MediaStream?>[localStream, remoteStream];

    if ((sourceVideo == null || sourceVideo.getTracks().isEmpty) &&
        sourceAudio.every((s) => s == null || s.getAudioTracks().isEmpty)) {
      return;
    }

    _mimeType = _pickMime(video);
    _recordingStream = await createLocalMediaStream('veto_call_recording');

    if (video) {
      final track = sourceVideo?.getVideoTracks().isNotEmpty == true
          ? sourceVideo!.getVideoTracks().first
          : null;
      if (track != null) {
        await _recordingStream!.addTrack(track, addToNative: false);
      }
    }

    for (final stream in sourceAudio) {
      if (stream == null) continue;
      for (final t in stream.getAudioTracks()) {
        await _recordingStream!.addTrack(t, addToNative: false);
      }
    }

    final s = _recordingStream;
    if (s is! MediaStreamWeb) {
      return;
    }

    final opts = video
        ? web.MediaRecorderOptions(
            mimeType: _mimeType,
            audioBitsPerSecond: _kAudioBps,
            videoBitsPerSecond: _kVideoBps,
          )
        : web.MediaRecorderOptions(
            mimeType: _mimeType,
            audioBitsPerSecond: _kAudioBps,
          );

    _urlCompleter = Completer<String>();
    _rec = web.MediaRecorder(s.jsStream, opts);
    final recorder = _rec!;

    void onDataAvailable(web.Event event) {
      final blob = (event as web.BlobEvent).data;
      if (blob.size > 0) {
        _chunks.add(blob);
      }
      if (recorder.state == 'inactive') {
        if (_urlCompleter != null && !_urlCompleter!.isCompleted) {
          if (_chunks.isEmpty) {
            _urlCompleter!.complete('');
          } else {
            final b = web.Blob(_chunks.toJS, web.BlobPropertyBag(type: _mimeType));
            _urlCompleter!.complete(web.URL.createObjectURL(b));
          }
        }
      }
    }

    void onError(JSAny e) {
      if (_urlCompleter != null && !_urlCompleter!.isCompleted) {
        _urlCompleter!.completeError(e);
      }
    }

    recorder.addEventListener('dataavailable', onDataAvailable.toJS);
    recorder.addEventListener('error', onError.toJS);
    recorder.start(_kTimeSliceMs);
  }

  @override
  Future<CallRecordingResult?> stop() async {
    if (_rec == null || _urlCompleter == null) {
      return null;
    }
    try {
      _rec!.requestData();
    } catch (_) {}
    _rec!.stop();
    var objectUrl = '';
    try {
      objectUrl = await _urlCompleter!.future
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      return null;
    } finally {
      _rec = null;
      _urlCompleter = null;
      _recordingStream = null;
      _chunks.clear();
    }
    if (objectUrl.isEmpty) {
      return null;
    }

    try {
      final response = await http.get(Uri.parse(objectUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final u8 = Uint8List.fromList(response.bodyBytes);
      return CallRecordingResult(
        bytes: u8,
        mimeType: _mimeType,
        fileName: _isVideo
            ? 'veto-call.webm'
            : 'veto-call-audio.webm',
      );
    } finally {
      web.URL.revokeObjectURL(objectUrl);
    }
  }
}

CallRecordingService createCallRecordingServiceImpl() =>
    _WebCallRecordingService();
