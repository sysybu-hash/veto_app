// Split from veto_screen.dart — admin helpers, chat row model.
part of '../veto_screen.dart';

String? _mongoEventId(dynamic ev) {
  final id = ev['_id'];
  if (id == null) return null;
  if (id is String) return id.isEmpty ? null : id;
  if (id is Map) {
    final o = id[r'$oid'] ?? id['oid'];
    if (o != null) return o.toString();
  }
  final t = id.toString();
  return (t.isEmpty || t == 'null') ? null : t;
}

// ── Chat message ──────────────────────────────────────────
class _Msg {
  final String text;
  final bool isUser, isSystem;
  /// True when assistant text came from Gemini Multimodal Live with native audio playback.
  final bool hadNativeAudio;
  _Msg({
    required this.text,
    required this.isUser,
    this.isSystem = false,
    this.hadNativeAudio = false,
  });
}
