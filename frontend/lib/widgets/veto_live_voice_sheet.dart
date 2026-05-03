import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/veto_live_audio_prefs.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';

class VetoLiveVoiceSheet extends StatefulWidget {
  const VetoLiveVoiceSheet({super.key});

  @override
  State<VetoLiveVoiceSheet> createState() => _VetoLiveVoiceSheetState();
}

class _VetoLiveVoiceSheetState extends State<VetoLiveVoiceSheet> {
  late String _voice;
  late double _gain;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final v = await VetoLiveAudioPrefs.getVoice();
    final g = await VetoLiveAudioPrefs.getGain();
    if (!mounted) return;
    setState(() {
      _voice = v;
      _gain = g;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppLanguageController>().code;
    final t = _VetoLiveVoiceCopy.fromLang(lang);
    if (!_ready) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: V26.navy600),
        ),
      );
    }
    if (!kIsWeb) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t.webOnly,
          style: const TextStyle(color: V26.ink900),
        ),
      );
    }
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: V26.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              t.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: V26.ink900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: V26.ink500,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.voiceLabel,
              style: const TextStyle(
                color: V26.ink300,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: V26.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: V26.hairline),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: VetoLiveAudioPrefs.normalizeVoice(_voice),
                  dropdownColor: const Color(0xFF0B1220),
                  style: const TextStyle(
                    color: V26.ink900,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  items: VetoLiveAudioPrefs.kVoiceOptions
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _voice = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.gainLabel,
              style: const TextStyle(
                color: V26.ink300,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.volume_mute,
                  size: 20,
                  color: V26.ink500,
                ),
                Expanded(
                  child: Slider(
                    value: _gain,
                    onChanged: (g) => setState(() => _gain = g),
                    activeColor: V26.navy600,
                    inactiveColor: V26.hairline,
                  ),
                ),
                const Icon(
                  Icons.volume_up,
                  size: 20,
                  color: V26.ink500,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await VetoLiveAudioPrefs.setVoice(_voice);
                await VetoLiveAudioPrefs.setGain(_gain);
                if (context.mounted) Navigator.of(context).pop<String>(_voice);
              },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _VetoLiveVoiceCopy {
  const _VetoLiveVoiceCopy({
    required this.title,
    required this.hint,
    required this.voiceLabel,
    required this.gainLabel,
    required this.save,
    required this.webOnly,
  });

  final String title, hint, voiceLabel, gainLabel, save, webOnly;

  factory _VetoLiveVoiceCopy.fromLang(String lang) {
    switch (AppLanguage.normalize(lang)) {
      case 'ru':
        return const _VetoLiveVoiceCopy(
          title: 'Голос Gemini Live',
          hint: 'Предзаписанные голоса. Громкость влогает на воспроизведение (PCM) в этом браузере. Начните сессию снова после смены голоса.',
          voiceLabel: 'Голос',
          gainLabel: 'Громкость ответа',
          save: 'Сохранить',
          webOnly: 'Мультимодальное прямое аудио Gemini (Live) доступно только в веб-версии.',
        );
      case 'en':
        return const _VetoLiveVoiceCopy(
          title: 'Gemini Live voice',
          hint: 'Prebuilt model voices. Gain applies to native PCM playback in this browser. Start a new mic session after changing the voice.',
          voiceLabel: 'Voice',
          gainLabel: 'Reply volume',
          save: 'Save',
          webOnly: 'Gemini Multimodal Live audio is only available in the web app.',
        );
      default:
        return const _VetoLiveVoiceCopy(
          title: 'הגדרות שמע – Gemini Live',
          hint: 'מצבים קבועים מראש של קול. העוצמה משפיעה על שמע המודל (PCM) בדפדפן. אחרי שינוי קול, הפעל מחדש את ה-session מהמיקרופון.',
          voiceLabel: 'דיבור (קול)',
          gainLabel: 'עוצמת תשובה',
          save: 'שמור',
          webOnly: 'שמע Live מלא (Multimodal) קיים בגרסת הווב בלבד.',
        );
    }
  }
}

Future<String?> showVetoLiveVoiceSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: V26.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const VetoLiveVoiceSheet(),
  );
}
