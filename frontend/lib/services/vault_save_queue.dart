// Background pipeline: after a call, compress, upload to API + save copies to
// the vault. Survives navigation because it lives in a top-level [ChangeNotifier].

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import 'call_api_service.dart';
import 'call_recording_service.dart' show CallRecordingResult;
import 'vault_payload_compress.dart';

/// One in-flight or finished save operation shown in the vault screen.
class VaultSaveJob {
  VaultSaveJob({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
  double progress = 0; // 0.0 - 1.0
  String statusLine = '';
  String? error;
  bool isDone = false;
}

class VaultSaveQueue extends ChangeNotifier {
  VaultSaveQueue() : _api = CallApiService();

  final List<VaultSaveJob> _jobs = [];
  final CallApiService _api;
  int _idCounter = 0;
  final Set<String> _enqueuedAgoraTranscribe = {};

  /// Bumped when a call-related save has finished; [FilesVaultScreen] refreshes the list.
  final ValueNotifier<int> listRefresh = ValueNotifier(0);

  /// In-flight and recently finished rows (newest first), until dismissed or time-out.
  List<VaultSaveJob> get visibleJobs {
    return _jobs.reversed.toList(growable: false);
  }

  String _newId() => 'vs-${++_idCounter}-${DateTime.now().millisecondsSinceEpoch}';

  void _updateJob(VaultSaveJob job, {double? p, String? line}) {
    if (p != null) job.progress = p.clamp(0.0, 1.0);
    if (line != null) job.statusLine = line;
    notifyListeners();
  }

  void _finishJob(VaultSaveJob job, {String? err}) {
    job.isDone = true;
    job.error = err;
    job.progress = err == null ? 1.0 : job.progress;
    if (err != null) {
      job.statusLine = err;
    } else {
      listRefresh.value++;
      // Drop successful rows from the header after a short moment.
      Future<void>.delayed(const Duration(seconds: 3), () {
        _jobs.remove(job);
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /// After a call, if a recording was uploaded to the event on the server,
  /// run transcription and save the transcript to the vault.
  void enqueueAgoraRecordingTranscript({
    required String eventId,
    required String language,
    String? roomLabel,
  }) {
    if (eventId.isEmpty) return;
    if (_enqueuedAgoraTranscribe.contains(eventId)) return;
    _enqueuedAgoraTranscribe.add(eventId);
    final job = VaultSaveJob(
      id: _newId(),
      label: roomLabel ?? 'תמלול שיחה',
    );
    _jobs.add(job);
    if (_jobs.length > 8) {
      _jobs.removeAt(0);
    }
    notifyListeners();
    unawaited(
      _runAgoraTranscript(
        job,
        eventId: eventId,
        language: language,
      ),
    );
  }

  /// Enqueue a full post-call pipeline (client recording + transcribe + vault).
  void enqueueCallMediaArtifacts({
    required String eventId,
    required String language,
    String? roomLabel,
    CallRecordingResult? recording,
  }) {
    if (eventId.isEmpty || recording == null || recording.bytes.isEmpty) {
      return;
    }
    final job = VaultSaveJob(
      id: _newId(),
      label: roomLabel ?? 'שמירה מהשיחה',
    );
    _jobs.add(job);
    if (_jobs.length > 8) {
      _jobs.removeAt(0);
    }
    notifyListeners();

    unawaited(
      _runCallMedia(
        job,
        eventId: eventId,
        language: language,
        recording: recording,
      ),
    );
  }

  /// Chat-only: transcript to vault.
  void enqueueChatTranscript({
    required String eventId,
    required String transcript,
    String? roomLabel,
  }) {
    if (transcript.trim().isEmpty) return;
    final job = VaultSaveJob(
      id: _newId(),
      label: roomLabel ?? 'תמלול צ\'אט',
    );
    _jobs.add(job);
    if (_jobs.length > 8) {
      _jobs.removeAt(0);
    }
    notifyListeners();
    unawaited(
      _runChatOnly(
        job,
        eventId: eventId,
        transcript: transcript,
      ),
    );
  }

  void dismissJob(String id) {
    _jobs.removeWhere((j) => j.id == id);
    notifyListeners();
  }

  Future<void> _runAgoraTranscript(
    VaultSaveJob job, {
    required String eventId,
    required String language,
  }) async {
    try {
      _updateJob(job, p: 0.1, line: 'ממליל…');
      final tText = await _api.transcribeFromStoredRecording(
        eventId: eventId,
        language: language,
      );
      if (tText == null || tText.trim().isEmpty) {
        _finishJob(
          job,
          err: 'אין הקלטה בשרת או תמלול לא זמין (Agora ללא Cloud Recording)',
        );
        return;
      }
      _updateJob(job, p: 0.4, line: 'מדחס תמלול…');
      final tr = compressTranscriptForVault(
        tText,
        eventId: eventId,
      );
      await _saveTranscriptToVault(
        job,
        comp: tr,
        progressStart: 0.45,
        progressEnd: 1,
        label: 'שומר בכספת…',
      );
      _updateJob(job, p: 1, line: 'הושלם');
      _finishJob(job);
    } catch (e) {
      _finishJob(
        job,
        err: e is Exception ? e.toString() : 'השמירה נכשלה',
      );
    }
  }

  Future<void> _runCallMedia(
    VaultSaveJob job, {
    required String eventId,
    required String language,
    required CallRecordingResult recording,
  }) async {
    try {
      _updateJob(job, p: 0.01, line: 'מכווץ…');
      await Future<void>.delayed(Duration.zero);
      final rec = recording;
      final mediaComp = compressMediaForVault(
        rec.bytes,
        eventId: eventId,
        baseName: 'veto-call-$eventId.webm',
        defaultMime: rec.mimeType,
      );
      if (rec.bytes.isNotEmpty) {
        _updateJob(job, p: 0.04, line: 'מעלה לשרת…');
        const base = 0.04;
        const span = 0.4;
        await _api.uploadRecordingWithProgress(
          eventId: eventId,
          bytes: rec.bytes,
          fileName: rec.fileName,
          onProgress: (s, t) {
            if (t <= 0) return;
            _updateJob(
              job,
              p: base + span * (s / t),
              line: 'מעלה הקלטה… ${(100 * s / t).round()}%',
            );
          },
        );
      }

      _updateJob(job, p: 0.5, line: 'ממליל…');
      String? tText;
      if (rec.bytes.isNotEmpty) {
        tText = await _api.transcribeRecording(
          eventId: eventId,
          bytes: rec.bytes,
          mimeType: rec.mimeType,
          language: language,
        );
      }
      if (tText == null || tText.trim().isEmpty) {
        _updateJob(
          job,
          p: 0.6,
          line: 'אין תמלול — שומר מדיה בכספת',
        );
        await _saveMediaOnlyVault(
          job,
          from: 0.65,
          to: 1,
          media: mediaComp,
        );
        _updateJob(job, p: 1, line: 'הושלם');
        _finishJob(job);
        return;
      }
      _updateJob(job, p: 0.7, line: 'מדחס תמלול…');
      final tr = compressTranscriptForVault(
        tText,
        eventId: eventId,
      );
      await _saveTranscriptToVault(
        job,
        comp: tr,
        progressStart: 0.72,
        progressEnd: 0.9,
        label: 'שומר תמלול…',
      );
      await _saveMediaOnlyVault(
        job,
        from: 0.9,
        to: 1,
        media: mediaComp,
        label: 'שומר הקלטה בכספת…',
      );
      _updateJob(job, p: 1, line: 'הושלם');
      _finishJob(job);
    } catch (e) {
      _finishJob(
        job,
        err: e is Exception
            ? e.toString()
            : 'השמירה נכשלה',
      );
    }
  }

  Future<void> _runChatOnly(
    VaultSaveJob job, {
    required String eventId,
    required String transcript,
  }) async {
    try {
      _updateJob(job, p: 0.05, line: 'מדחס…');
      final tr = compressTranscriptForVault(
        transcript,
        eventId: eventId,
      );
      await _saveTranscriptToVault(
        job,
        comp: tr,
        progressStart: 0.1,
        progressEnd: 0.9,
        label: 'שומר בכספת…',
      );
      _updateJob(job, p: 1, line: 'הושלם');
      _finishJob(job);
    } catch (e) {
      _finishJob(
        job,
        err: e is Exception
            ? e.toString()
            : 'השמירה נכשלה',
      );
    }
  }

  Future<void> _saveTranscriptToVault(
    VaultSaveJob job, {
    required VaultCompressedBlob comp,
    required double progressStart,
    required double progressEnd,
    String label = 'מעלה…',
  }) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw StateError('אין אסימון');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/vault/files/upload'),
    );
    request.headers.addAll(
      AppConfig.httpHeadersBinary({'Authorization': 'Bearer $token'}),
    );
    final len = comp.bytes.length;
    Stream<List<int>> chunk() async* {
      const c = 16 * 1024;
      for (var i = 0; i < comp.bytes.length; i += c) {
        final j = (i + c < comp.bytes.length) ? i + c : comp.bytes.length;
        final t = (progressStart +
                (progressEnd - progressStart) * (j / len))
            .clamp(0.0, 1.0);
        _updateJob(
          job,
          p: t,
          line:
              '$label ${(100 * j / len).round()}%',
        );
        yield comp.bytes.sublist(i, j);
        await Future<void>.delayed(Duration.zero);
      }
    }

    request.fields['name'] = comp.fileName;
    request.fields['mimeType'] = comp.mimeType;
    request.files.add(
      http.MultipartFile(
        'file',
        http.ByteStream(chunk()),
        len,
        filename: comp.fileName,
      ),
    );
    final res = await request.send();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final b = await res.stream.bytesToString();
      throw Exception('vault: ${res.statusCode} $b');
    }
  }

  Future<void> _saveMediaOnlyVault(
    VaultSaveJob job, {
    required double from,
    required double to,
    required VaultCompressedBlob media,
    String label = 'מעלה מדיה…',
  }) async {
    if (media.bytes.isEmpty) {
      return;
    }
    final token = await AuthService().getToken();
    if (token == null) {
      return;
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/vault/files/upload'),
    );
    request.headers.addAll(
      AppConfig.httpHeadersBinary({'Authorization': 'Bearer $token'}),
    );
    final len = media.bytes.length;
    Stream<List<int>> chunk() async* {
      const c = 32 * 1024;
      for (var i = 0; i < media.bytes.length; i += c) {
        final j = (i + c < media.bytes.length) ? i + c : media.bytes.length;
        _updateJob(
          job,
          p: (from + (to - from) * (j / len)).clamp(0.0, 1.0),
          line: '$label ${(100 * j / len).round()}%',
        );
        yield media.bytes.sublist(i, j);
      }
    }
    request.fields['name'] = media.fileName;
    request.fields['mimeType'] = media.mimeType;
    request.files.add(
      http.MultipartFile(
        'file',
        http.ByteStream(chunk()),
        len,
        filename: media.fileName,
      ),
    );
    final res = await request.send();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final b = await res.stream.bytesToString();
      throw Exception('vault media: ${res.statusCode} $b');
    }
  }
}
