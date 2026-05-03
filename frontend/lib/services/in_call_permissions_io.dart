// ============================================================
//  in_call_permissions_io.dart — native (iOS/Android/desktop) branch.
//  Delegates to `permission_handler` for mic + camera.
// ============================================================

import 'package:permission_handler/permission_handler.dart';

class CallPermissionsResult {
  const CallPermissionsResult({
    required this.microphoneGranted,
    required this.cameraGranted,
  });
  final bool microphoneGranted;
  final bool cameraGranted;

  bool get allGranted => microphoneGranted && cameraGranted;
}

/// Prompt for mic + camera (if [wantVideo]) before Agora tries to use them.
Future<CallPermissionsResult> requestCallPermissions({required bool wantVideo}) async {
  PermissionStatus mic = PermissionStatus.granted;
  PermissionStatus cam = PermissionStatus.granted;
  try {
    mic = await Permission.microphone.request();
  } catch (_) {}
  if (wantVideo) {
    try {
      cam = await Permission.camera.request();
    } catch (_) {}
  }
  return CallPermissionsResult(
    microphoneGranted: mic.isGranted || mic.isLimited,
    cameraGranted: !wantVideo || cam.isGranted || cam.isLimited,
  );
}
