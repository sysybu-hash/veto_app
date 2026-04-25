import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart';

void openInNewTab(String url) {
  window.open(url, '_blank');
}

void registerSttResultHandler(void Function(String result) handler) {
  (window as JSObject)['vetoSTTResult'] = ((JSString s) {
    handler(s.toDart);
  }).toJS;
}

void registerGeminiLiveResultHandler(void Function(String result) handler) {
  (window as JSObject)['vetoGeminiLiveResult'] = ((JSString s) {
    handler(s.toDart);
  }).toJS;
}

JSAny? _dynamicToJSAny(dynamic e) {
  if (e == null) return null;
  if (e is bool) return e.toJS;
  if (e is int) return e.toJS;
  if (e is double) return e.toJS;
  if (e is String) return e.toJS;
  return e as JSAny?;
}

Object? callBrowserMethod(String objectName, String methodName, List<dynamic> arguments) {
  final win = window as JSObject;
  final target = win[objectName];
  if (target == null) return null;
  final obj = target as JSObject;
  final args = arguments.map(_dynamicToJSAny).toList();
  return obj.callMethodVarArgs(methodName.toJS, args);
}

bool supportsBrowserMethod(String objectName, String methodName, List<dynamic> arguments) {
  try {
    return callBrowserMethod(objectName, methodName, arguments) as bool? ?? false;
  } catch (_) {
    return false;
  }
}

Future<String> googleSignInViaGIS(String clientId) async {
  final oauthRaw = window['vetoGoogleOAuth'];
  if (!oauthRaw.isA<JSFunction>()) {
    throw StateError('window.vetoGoogleOAuth is not defined');
  }
  final raw = (oauthRaw as JSFunction).callAsFunction(null, clientId.toJS);
  final jsp = raw as JSPromise<JSString>;
  final out = await jsp.toDart;
  return out.toDart;
}

void setupDragAndDropHandlers({
  required void Function() onDragOver,
  required void Function() onDragLeave,
  required void Function(List<dynamic> files) onDrop,
}) {
  document.addEventListener(
    'dragover',
    ((Event event) {
      event.preventDefault();
      onDragOver();
    }).toJS,
  );
  document.addEventListener(
    'dragleave',
    ((Event _) {
      onDragLeave();
    }).toJS,
  );
  document.addEventListener(
    'drop',
    ((Event event) {
      event.preventDefault();
      final de = event as DragEvent;
      final dt = de.dataTransfer;
      final fl = dt?.files;
      if (fl == null || fl.length == 0) return;
      final out = <File>[];
      for (var i = 0; i < fl.length; i++) {
        final f = fl.item(i);
        if (f != null) out.add(f);
      }
      onDrop(out);
    }).toJS,
  );
}

Future<Uint8List> readFileAsBytes(dynamic htmlFile) async {
  final file = htmlFile as File;
  final buf = await file.arrayBuffer().toDart;
  return buf.toDart.asUint8List();
}

String getFileName(dynamic htmlFile) => (htmlFile as File).name;
String getFileType(dynamic htmlFile) => (htmlFile as File).type;

void triggerCameraCapture(void Function(dynamic file) onFile) {
  pickEvidenceMedia().then((f) {
    if (f != null) onFile(f);
  });
}

/// `capture=environment` helps rear camera on phones but breaks many desktop browsers
/// (blank/black picker). Only set on likely mobile/tablet user agents.
bool shouldUseCaptureAttributeOnFileInput() {
  final ua = window.navigator.userAgent;
  if (ua.isEmpty) return false;
  final re = RegExp(
    r'Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|Mobile',
    caseSensitive: false,
  );
  return re.hasMatch(ua);
}

/// Opens the system file / camera picker (mobile web uses [capture] when supported).
/// Returns the first selected [File], or `null` if cancelled / empty.
///
/// [preferCameraCapture] — when true, adds `capture=environment` only on mobile UAs
/// (see [shouldUseCaptureAttributeOnFileInput]).
Future<dynamic> pickEvidenceMedia({bool preferCameraCapture = true}) async {
  final input = HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..multiple = false;
  if (preferCameraCapture && shouldUseCaptureAttributeOnFileInput()) {
    input.setAttribute('capture', 'environment');
  }
  input.style.setProperty('position', 'fixed');
  input.style.setProperty('left', '-9999px');
  input.style.setProperty('top', '0');
  input.style.setProperty('opacity', '0');
  input.style.setProperty('pointer-events', 'none');

  final completer = Completer<File?>();
  var done = false;

  late final JSFunction focusListener;

  void finish(File? f) {
    if (done) return;
    done = true;
    input.remove();
    window.removeEventListener('focus', focusListener);
    if (!completer.isCompleted) completer.complete(f);
  }

  focusListener = ((Event _) {
    if (done) return;
    // Picker closed: allow [onchange] to run first (order varies by browser).
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (done) return;
      final files = input.files;
      if (files != null && files.length > 0) {
        finish(files.item(0));
      } else {
        finish(null);
      }
    });
  }).toJS;

  input.onchange = ((Event _) {
    final files = input.files;
    if (files != null && files.length > 0) {
      final f = files.item(0);
      finish(f);
    } else {
      finish(null);
    }
  }).toJS;

  document.body!.appendChild(input);
  window.addEventListener('focus', focusListener);
  input.click();

  return completer.future;
}

Future<Map<String, dynamic>?> _mapFlowsJsResultToDart(JSAny? raw) async {
  if (raw == null) return null;
  // JS returns a Promise<object> from async setUser
  if (raw.isA<JSPromise>()) {
    final any = await (raw as JSPromise<JSAny?>).toDart;
    if (any == null) return null;
    return _stringifyJsObjectToMap(any);
  }
  return _stringifyJsObjectToMap(raw);
}

Map<String, dynamic>? _stringifyJsObjectToMap(JSAny any) {
  if (!any.isA<JSObject>()) return null;
  final jsonAny = (window as JSObject)['JSON'];
  if (jsonAny == null || !jsonAny.isA<JSObject>()) return null;
  final jsonStr =
      (jsonAny as JSObject).callMethod<JSString>('stringify'.toJS, any).toDart;
  final decoded = jsonDecode(jsonStr);
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  return null;
}

Future<Map<String, dynamic>?> flowsSetUser({
  required String userId,
  required String role,
  required String lang,
}) async {
  try {
    final win = window as JSObject;

    // `index.html` exposes this so we don't rely on host-object quirks for `vetoFlows`.
    final invoke = win['vetoFlowsInvoke'];
    if (invoke.isA<JSFunction>()) {
      return _mapFlowsJsResultToDart(
        (invoke as JSFunction)
            .callAsFunction(null, userId.toJS, role.toJS, lang.toJS),
      );
    }

    final flows = win['vetoFlows'];
    if (flows == null || !flows.isA<JSObject>()) {
      if (kDebugMode) {
        debugPrint(
          '[VETO Flows] missing window.vetoFlows (Flows module not loaded yet?)',
        );
      }
      return null;
    }
    final setUser = (flows as JSObject)['setUser'];
    if (setUser == null || !setUser.isA<JSFunction>()) {
      if (kDebugMode) {
        debugPrint('[VETO Flows] vetoFlows.setUser is not a function');
      }
      return null;
    }

    return _mapFlowsJsResultToDart(
      (setUser as JSFunction).callAsFunction(
        null,
        userId.toJS,
        role.toJS,
        lang.toJS,
      ),
    );
  } catch (e, st) {
    debugPrint('[VETO Flows] flowsSetUser: $e\n$st');
    return null;
  }
}
