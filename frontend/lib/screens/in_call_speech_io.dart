import 'package:speech_to_text/speech_to_text.dart' show ListenMode, SpeechListenOptions, SpeechToText;

InCallSpeech createInCallSpeech(void Function() onNotify) =>
    InCallSpeech._(onNotify);

/// Device speech-to-text (iOS / Android / desktop; not used on Web build).
class InCallSpeech {
  InCallSpeech._(this._notify);

  final void Function() _notify;
  final SpeechToText _speech = SpeechToText();

  bool _inited = false;
  bool listening = false;
  String? error;
  String partial = '';
  final List<String> lines = <String>[];

  String _localeId = 'he_IL';

  void setLanguageCode(String? lang) {
    final l = lang ?? 'he';
    if (l == 'he') {
      _localeId = 'he_IL';
    } else if (l == 'ru') {
      _localeId = 'ru_RU';
    } else if (l == 'ar') {
      _localeId = 'ar_SA';
    } else {
      _localeId = 'en_US';
    }
  }

  Future<void> toggle() async {
    if (listening) {
      try {
        await _speech.stop();
      } catch (_) {}
      listening = false;
      _notify();
      return;
    }
    if (!_inited) {
      error = null;
      _inited = await _speech.initialize(
        onError: (e) {
          error = e.errorMsg;
          _notify();
        },
        onStatus: (s) {
          if (s == 'notListening' || s == 'done') {
            listening = _speech.isListening;
            _notify();
          }
        },
      );
      if (!_inited) {
        error = 'Could not start speech recognition.';
        _notify();
        return;
      }
    }
    error = null;
    partial = '';
    _notify();
    try {
      await _speech.listen(
        onResult: (r) {
          if (r.finalResult) {
            final w = r.recognizedWords.trim();
            if (w.isNotEmpty) {
              lines.add(w);
              partial = '';
            }
          } else {
            partial = r.recognizedWords;
          }
          _notify();
        },
        localeId: _localeId,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 30),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
        ),
      );
      listening = _speech.isListening;
      _notify();
    } catch (e) {
      error = e.toString();
      _notify();
    }
  }

  Future<void> dispose() async {
    if (listening) {
      try {
        await _speech.stop();
      } catch (_) {}
      listening = false;
    }
  }
}
