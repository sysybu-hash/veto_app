import 'package:shared_preferences/shared_preferences.dart';

/// Persisted Gemini Live (web) voice + output gain. Keys versioned to avoid collisions.
class VetoLiveAudioPrefs {
  VetoLiveAudioPrefs._();

  static const String kVoice = 'veto_gemini_live_voice_v1';
  static const String kGain = 'veto_gemini_live_gain_v1';

  /// Prebuilt voice names for Live connect — must be a subset of [allowedLiveVoices] on the server.
  static const List<String> kVoiceOptions = <String>[
    'Kore',
    'Puck',
    'Charon',
    'Fenrir',
    'Zephyr',
    'Aoede',
  ];

  static String normalizeVoice(String? v) {
    if (v == null) return 'Kore';
    final t = v.trim();
    if (kVoiceOptions.contains(t)) return t;
    return 'Kore';
  }

  static Future<String> getVoice() async {
    final p = await SharedPreferences.getInstance();
    return normalizeVoice(p.getString(kVoice));
  }

  static Future<double> getGain() async {
    final p = await SharedPreferences.getInstance();
    final g = p.getDouble(kGain);
    if (g == null) return 0.85;
    return g.clamp(0.0, 1.0);
  }

  static Future<void> setVoice(String voice) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kVoice, normalizeVoice(voice));
  }

  static Future<void> setGain(double gain) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(kGain, gain.clamp(0.0, 1.0));
  }
}
