// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_recording_service.dart';

class _WebCallRecordingService implements CallRecordingService {
  MediaRecorder? _recorder;
  MediaStream? _recordingStream;
  String _mimeType = 'audio/webm';

  @override
  bool get isSupported => kIsWeb;

  @override
  Future<void> start({
    required MediaStream? localStream,
    required MediaStream? remoteStream,
    required bool video,
  }) async {
    if (!isSupported || _recorder != null) return;

    final sourceVideo = remoteStream?.getVideoTracks().isNotEmpty == true
        ? remoteStream
        : localStream;
    final sourceAudio = <MediaStream?>[localStream, remoteStream];

    if ((sourceVideo == null || sourceVideo.getTracks().isEmpty) &&
        sourceAudio.every((stream) => stream == null || stream.getTracks().isEmpty)) {
      return;
    }

    _mimeType = video ? 'video/webm' : 'audio/webm';
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
      for (final track in stream.getAudioTracks()) {
        await _recordingStream!.addTrack(track, addToNative: false);
      }
    }

    _recorder = MediaRecorder();
    _recorder!.startWeb(
      _recordingStream!,
      mimeType: _mimeType,
      timeSlice: 1000,
    );
  }

  @override
  Future<CallRecordingResult?> stop() async {
    final recorder = _recorder;
    if (recorder == null) return null;

    _recorder = null;
    final objectUrl = await recorder.stop() as String?;
    if (objectUrl == null || objectUrl.isEmpty) return null;

    try {
      final request = await html.HttpRequest.request(
        objectUrl,
        responseType: 'arraybuffer',
      );
      final buffer = request.response as ByteBuffer?;
      if (buffer == null) return null;
      final bytes = Uint8List.view(buffer);
      return CallRecordingResult(
        bytes: bytes,
        mimeType: _mimeType,
        fileName: _mimeType.startsWith('video')
            ? 'veto-call.webm'
            : 'veto-call-audio.webm',
      );
    } finally {
      html.Url.revokeObjectUrl(objectUrl);
    }
  }
}

CallRecordingService createCallRecordingServiceImpl() =>
    _WebCallRecordingService();
