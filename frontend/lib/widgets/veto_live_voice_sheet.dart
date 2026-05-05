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
  late String _lang;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final v = await VetoLiveAudioPrefs.getVoice();
    final g = await VetoLiveAudioPrefs.getGain();
    final l = await VetoLiveAudioPrefs.getLang();
    if (!mounted) return;
    setState(() {
      _voice = v;
      _gain = g;
      _lang = l;
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
            const SizedBox(height: 6),
            Text(
              t.autoSave,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: V26.navy600.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.langLabel,
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
                  value: VetoLiveAudioPrefs.normalizeLang(_lang),
                  dropdownColor: const Color(0xFF0B1220),
                  style: const TextStyle(
                    color: V26.ink900,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [
                    for (final code in VetoLiveAudioPrefs.kLangOptions)
                      DropdownMenuItem(
                        value: code,
                        child: Text(t.langName(code)),
                      ),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _lang = v);
                    await VetoLiveAudioPrefs.setLang(v);
                  },
                ),
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
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _voice = v);
                    await VetoLiveAudioPrefs.setVoice(v);
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
                    onChanged: (g) {
                      setState(() => _gain = g);
                      unawaited(VetoLiveAudioPrefs.setGain(g));
                    },
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
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.close),
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
    required this.autoSave,
    required this.langLabel,
    required this.voiceLabel,
    required this.gainLabel,
    required this.close,
    required this.webOnly,
    required this.langHe,
    required this.langEn,
    required this.langRu,
    required this.langAr,
  });

  final String title,
      hint,
      autoSave,
      langLabel,
      voiceLabel,
      gainLabel,
      close,
      webOnly,
      langHe,
      langEn,
      langRu,
      langAr;

  String langName(String code) {
    switch (code) {
      case 'en':
        return langEn;
      case 'ru':
        return langRu;
      case 'ar':
        return langAr;
      default:
        return langHe;
    }
  }

  factory _VetoLiveVoiceCopy.fromLang(String lang) {
    switch (AppLanguage.normalize(lang)) {
      case 'ru':
        return const _VetoLiveVoiceCopy(
          title: 'Настройки Gemini Live',
          hint:
              'Голос и язык ответа задают токен сессии на сервере. Громкость — только воспроизведение PCM в браузере. После смены голоса или языка начните новый сеанс с микрофона.',
          autoSave: 'Изменения сохраняются автоматически.',
          langLabel: 'Язык речи и инструкции (Live)',
          voiceLabel: 'Голос',
          gainLabel: 'Громкость ответа',
          close: 'Готово',
          webOnly: 'Мультимодальное прямое аудио Gemini (Live) доступно только в веб-версии.',
          langHe: 'עברית',
          langEn: 'English',
          langRu: 'Русский',
          langAr: 'العربية',
        );
      case 'en':
        return const _VetoLiveVoiceCopy(
          title: 'Gemini Live settings',
          hint:
              'Speech language and voice are sent when creating the Live token on the server. Output gain only affects native PCM playback in this browser. Start a new mic session after changing voice or language.',
          autoSave: 'Changes save automatically.',
          langLabel: 'Live speech & instruction language',
          voiceLabel: 'Voice',
          gainLabel: 'Reply volume',
          close: 'Done',
          webOnly: 'Gemini Multimodal Live audio is only available in the web app.',
          langHe: 'Hebrew',
          langEn: 'English',
          langRu: 'Russian',
          langAr: 'Arabic',
        );
      default:
        return const _VetoLiveVoiceCopy(
          title: 'הגדרות Gemini Live',
          hint:
              'שפת הדיבור והקול נשלחים לשרת בעת יצירת ה-session. עוצמת השמע משפיעה רק על נגינת ה-PCM בדפדפן. אחרי שינוי קול או שפה — הפעל מחדש שיחה מהמיקרופון.',
          autoSave: 'השינויים נשמרים אוטומטית.',
          langLabel: 'שפת דיבור והנחיות (Live)',
          voiceLabel: 'קול (דיבור)',
          gainLabel: 'עוצמת תשובה',
          close: 'סיום',
          webOnly: 'שמע Live מלא (Multimodal) קיים בגרסת הווב בלבד.',
          langHe: 'עברית',
          langEn: 'English',
          langRu: 'Русский',
          langAr: 'العربية',
        );
    }
  }
}

Future<void> showVetoLiveVoiceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: V26.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const VetoLiveVoiceSheet(),
  );
}
