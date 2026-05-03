// ============================================================
//  in_call_permissions.dart — pre-join camera/mic prompt bridge.
//
//  * Native (iOS/Android/desktop): permission_handler.
//  * Web: a small dart:js_interop getUserMedia prompt that pops the
//    browser's native permission dialog before Agora tries to use
//    the devices. Agora's Web SDK does prompt implicitly, but the
//    prompt arrives late and can mask why a join "hangs" — we prefer
//    to fail fast here with a clear error.
// ============================================================

export 'in_call_permissions_io.dart'
    if (dart.library.html) 'in_call_permissions_web.dart';
