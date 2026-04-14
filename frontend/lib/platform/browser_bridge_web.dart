import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart';

void openInNewTab(String url) {
  window.open(url, '_blank');
}

void registerSttResultHandler(void Function(String result) handler) {
  (window as JSObject)['vetoSTTResult'] = ((JSString s) {
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
  final input = HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*,video/*';
  input.setAttribute('capture', 'environment');
  input.onchange = ((Event _) {
    final files = input.files;
    if (files == null) return;
    for (var i = 0; i < files.length; i++) {
      final f = files.item(i);
      if (f != null) onFile(f);
    }
  }).toJS;
  input.click();
}
