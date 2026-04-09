import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}

void registerSttResultHandler(void Function(String result) handler) {
  js.context['vetoSTTResult'] = handler;
}

Object? callBrowserMethod(String objectName, String methodName, List<dynamic> arguments) {
  return js.context[objectName].callMethod(methodName, arguments);
}

bool supportsBrowserMethod(String objectName, String methodName, List<dynamic> arguments) {
  try {
    return callBrowserMethod(objectName, methodName, arguments) as bool? ?? false;
  } catch (_) {
    return false;
  }
}

Future<String> googleSignInViaGIS(String clientId) async {
  final promise = js_util.callMethod(html.window, 'vetoGoogleOAuth', [clientId]);
  return await js_util.promiseToFuture<String>(promise);
}

void setupDragAndDropHandlers({
  required void Function() onDragOver,
  required void Function() onDragLeave,
  required void Function(List<dynamic> files) onDrop,
}) {
  html.document.addEventListener('dragover', (event) {
    event.preventDefault();
    onDragOver();
  });
  html.document.addEventListener('dragleave', (event) {
    onDragLeave();
  });
  html.document.addEventListener('drop', (event) {
    event.preventDefault();
    final dt = (event as html.MouseEvent).dataTransfer;
    if (dt.files != null && dt.files!.isNotEmpty) {
      onDrop(dt.files!);
    }
  });
}

Future<Uint8List> readFileAsBytes(dynamic htmlFile) async {
  final file = htmlFile as html.File;
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;
  return (reader.result as ByteBuffer).asUint8List();
}

String getFileName(dynamic htmlFile) => (htmlFile as html.File).name;
String getFileType(dynamic htmlFile) => (htmlFile as html.File).type;