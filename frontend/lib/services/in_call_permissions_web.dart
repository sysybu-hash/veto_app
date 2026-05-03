// ============================================================
//  in_call_permissions_web.dart — Flutter Web branch.
//  Uses `navigator.mediaDevices.getUserMedia` to surface the
//  browser prompt BEFORE Agora initializes, so failures come
//  back with actionable errors instead of a silent join hang.
// ============================================================

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';

import 'dart:html' as html;

class CallPermissionsResult {
  const CallPermissionsResult({
    required this.microphoneGranted,
    required this.cameraGranted,
  });
  final bool microphoneGranted;
  final bool cameraGranted;

  bool get allGranted => microphoneGranted && cameraGranted;
}

Future<CallPermissionsResult> requestCallPermissions({required bool wantVideo}) async {
  final mediaDevices = html.window.navigator.mediaDevices;
  if (mediaDevices == null) {
    return const CallPermissionsResult(
      microphoneGranted: false,
      cameraGranted: false,
    );
  }
  final constraints = <String, dynamic>{
    'audio': true,
    if (wantVideo) 'video': true,
  };
  try {
    final stream = await mediaDevices.getUserMedia(constraints);
    // Stop all tracks immediately — Agora will request its own streams.
    for (final track in stream.getTracks()) {
      try {
        track.stop();
      } catch (_) {}
    }
    // Let the browser fully release devices before Agora opens its own
    // getUserMedia (avoids black preview / empty tracks on Chrome).
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return CallPermissionsResult(
      microphoneGranted: true,
      cameraGranted: !wantVideo || true,
    );
  } catch (_) {
    // Fallback: audio-only retry when the video grab was rejected.
    if (wantVideo) {
      try {
        final stream = await mediaDevices.getUserMedia({'audio': true});
        for (final track in stream.getTracks()) {
          try {
            track.stop();
          } catch (_) {}
        }
        await Future<void>.delayed(const Duration(milliseconds: 160));
        return const CallPermissionsResult(
          microphoneGranted: true,
          cameraGranted: false,
        );
      } catch (_) {
        // fall through
      }
    }
    return const CallPermissionsResult(
      microphoneGranted: false,
      cameraGranted: false,
    );
  }
}
