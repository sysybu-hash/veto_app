import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Result of optimizing payloads before vault upload.
class VaultCompressedBlob {
  const VaultCompressedBlob({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    this.wasCompressed = false,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final bool wasCompressed;
}

/// Gzip text when it actually shrinks the payload; otherwise keep UTF-8 .txt.
VaultCompressedBlob compressTranscriptForVault(
  String transcript, {
  required String eventId,
}) {
  final raw = Uint8List.fromList(utf8.encode(transcript));
  final gz = GZipEncoder().encode(raw);
  if (gz != null && gz.length < raw.length) {
    return VaultCompressedBlob(
      bytes: Uint8List.fromList(gz),
      fileName: 'veto-transcript-$eventId.txt.gz',
      mimeType: 'application/gzip',
      wasCompressed: true,
    );
  }
  return VaultCompressedBlob(
    bytes: raw,
    fileName: 'veto-transcript-$eventId.txt',
    mimeType: 'text/plain; charset=utf-8',
  );
}

/// Optional gzip for media — only if the archive is meaningfully smaller.
VaultCompressedBlob compressMediaForVault(
  Uint8List bytes, {
  required String eventId,
  required String baseName,
  required String defaultMime,
}) {
  if (bytes.isEmpty) {
    return VaultCompressedBlob(
      bytes: bytes,
      fileName: baseName,
      mimeType: defaultMime,
    );
  }
  final gz = GZipEncoder().encode(bytes);
  if (gz != null && gz.length < (bytes.length * 0.92)) {
    return VaultCompressedBlob(
      bytes: Uint8List.fromList(gz),
      fileName: '$baseName.gz',
      mimeType: 'application/gzip',
      wasCompressed: true,
    );
  }
  return VaultCompressedBlob(
    bytes: bytes,
    fileName: baseName,
    mimeType: defaultMime,
  );
}
