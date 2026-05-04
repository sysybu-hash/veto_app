import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readRecordingFileBytes(String path) async {
  if (path.isEmpty) return null;
  final f = File(path);
  if (!await f.exists()) return null;
  return f.readAsBytes();
}

Future<void> deleteRecordingFileIfExists(String path) async {
  if (path.isEmpty) return;
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
