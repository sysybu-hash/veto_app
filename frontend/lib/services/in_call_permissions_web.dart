// ============================================================
//  in_call_permissions_web.dart — Flutter Web branch.
//  Uses `navigator.mediaDevices.getUserMedia` (package:web) to
//  surface the browser prompt BEFORE Agora initializes.
// ============================================================

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

class CallPermissionsResult {
  const CallPermissionsResult({
    required this.microphoneGranted,
    required this.cameraGranted,
  });
  final bool microphoneGranted;
  final bool cameraGranted;

  bool get allGranted => microphoneGranted && cameraGranted;
}

void _stopAllTracks(MediaStream stream) {
  for (final track in stream.getTracks().toDart) {
    try {
      track.stop();
    } catch (_) {}
  }
}

Future<CallPermissionsResult> requestCallPermissions({required bool wantVideo}) async {
  final mediaDevices = window.navigator.mediaDevices;
  try {
    if (wantVideo) {
      final stream = await mediaDevices
          .getUserMedia(MediaStreamConstraints(audio: true.toJS, video: true.toJS))
          .toDart;
      _stopAllTracks(stream);
    } else {
      final stream =
          await mediaDevices.getUserMedia(MediaStreamConstraints(audio: true.toJS)).toDart;
      _stopAllTracks(stream);
    }
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return CallPermissionsResult(
      microphoneGranted: true,
      cameraGranted: wantVideo,
    );
  } catch (_) {
    if (wantVideo) {
      try {
        final stream =
            await mediaDevices.getUserMedia(MediaStreamConstraints(audio: true.toJS)).toDart;
        _stopAllTracks(stream);
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
