InCallSpeech createInCallSpeech(void Function() onNotify) =>
    InCallSpeech._(onNotify);

/// Web build: `speech_to_text` is not bundled; offer Vault transcript instead.
class InCallSpeech {
  InCallSpeech._(this._notify);

  final void Function() _notify;

  bool listening = false;
  String? error;
  String partial = '';
  final List<String> lines = <String>[];

  void setLanguageCode(String? _) {}

  Future<void> toggle() async {
    error =
        'כתוביות חיה מהמכשיר זמינות באפליקיית iOS/Android. בדפדפן, השתמשו בתמלול אחרי השיחה (Vault) כשיש הקלטה בשרת.';
    listening = false;
    _notify();
  }

  Future<void> dispose() async {}
}
