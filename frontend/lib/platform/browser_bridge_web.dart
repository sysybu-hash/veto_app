import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;

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

/// Triggers Google OAuth2 popup via GIS token client.
/// Returns the access_token on success, or throws on failure.
Future<String> googleSignInViaGIS(String clientId) async {
  // Must use js_util.callMethod on the html.window object so that
  // the return value is a native JS Promise (not a wrapped JsObject),
  // which is required by promiseToFuture.
  final promise = js_util.callMethod(html.window, 'vetoGoogleOAuth', [clientId]);
  return await js_util.promiseToFuture<String>(promise);
}