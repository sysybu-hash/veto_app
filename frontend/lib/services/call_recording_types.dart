import 'dart:typed_data';

/// Result of a local call recording (legacy WebRTC path removed; kept for vault pipeline).
class CallRecordingResult {
  const CallRecordingResult({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileName;
}
