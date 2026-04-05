import 'dart:html' as html;
import 'dart:js' as js;

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