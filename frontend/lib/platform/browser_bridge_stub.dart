void openInNewTab(String url) {}

void registerSttResultHandler(void Function(String result) handler) {}

Object? callBrowserMethod(String objectName, String methodName, List<dynamic> arguments) {
  return null;
}

bool supportsBrowserMethod(String objectName, String methodName, List<dynamic> arguments) {
  return false;
}

Future<String> googleSignInViaGIS(String clientId) async {
  throw UnsupportedError('Google Sign-In via GIS is only supported on web.');
}