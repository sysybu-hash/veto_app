import 'dart:typed_data';

void openInNewTab(String url) {}

void registerSttResultHandler(void Function(String result) handler) {}

void registerGeminiLiveResultHandler(void Function(String result) handler) {}

Object? callBrowserMethod(String objectName, String methodName, List<dynamic> arguments) {
  return null;
}

bool supportsBrowserMethod(String objectName, String methodName, List<dynamic> arguments) {
  return false;
}

Future<String> googleSignInViaGIS(String clientId) async {
  throw UnsupportedError('Google Sign-In via GIS is only supported on web.');
}

void setupDragAndDropHandlers({
  required void Function() onDragOver,
  required void Function() onDragLeave,
  required void Function(List<dynamic> files) onDrop,
}) {}

Future<Uint8List> readFileAsBytes(dynamic htmlFile) async {
  return Uint8List(0);
}

String getFileName(dynamic htmlFile) => '';
String getFileType(dynamic htmlFile) => '';

void triggerCameraCapture(void Function(dynamic file) onFile) {}

bool shouldUseCaptureAttributeOnFileInput() => false;

Future<dynamic> pickEvidenceMedia({bool preferCameraCapture = true}) async => null;

/// Heuristic: Web-only check (always false off-web).
bool isMobileBrowser() => false;

/// Flows (web-only). Returns a small status map from `window.vetoFlows.setUser(...)`.
Future<Map<String, dynamic>?> flowsSetUser({
  required String userId,
  required String role,
  required String lang,
}) async =>
    null;