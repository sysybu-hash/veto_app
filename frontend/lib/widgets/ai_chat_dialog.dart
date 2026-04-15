import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_theme.dart';

class AiChatDialog extends StatefulWidget {
  final String code;
  const AiChatDialog({super.key, required this.code});

  @override
  State<AiChatDialog> createState() => _AiChatDialogState();
}

class _AiChatDialogState extends State<AiChatDialog> {
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<Map<String, dynamic>> _history = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final greeting = widget.code == 'he'
        ? 'שלום! אני סייען VETO. איך אפשר לעזור לך היום?'
        : widget.code == 'ru'
            ? 'Здравствуйте! Я ассистент VETO. Чем могу помочь?'
            : 'Hello! I am the VETO assistant. How can I help you today?';
    _messages.add({'role': 'ai', 'text': greeting});
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });

    final res = await AiService().chat(
      message: text,
      history: List.from(_history),
      lang: widget.code,
    );

    _history.add({'role': 'user', 'parts': [{'text': text}]});
    _history.add({'role': 'model', 'parts': [{'text': res['reply'] ?? ''}]});

    if (!mounted) return;
    setState(() {
      _loading = false;
      _messages.add({'role': 'ai', 'text': res['reply'] ?? '...'});
    });
  }

  @override
  Widget build(BuildContext context) {
    final dir = AppLanguage.directionOf(widget.code);
    return Directionality(
      textDirection: dir,
      child: Dialog(
        backgroundColor: VetoPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: VetoPalette.primary),
                  const SizedBox(width: 8),
                  Text(
                    widget.code == 'he' ? 'סייען VETO' : widget.code == 'ru' ? 'Ассистент VETO' : 'VETO Assistant',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final m = _messages[i];
                    final isUser = m['role'] == 'user';
                    return Align(
                      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isUser ? VetoPalette.primary : VetoColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: isUser ? null : Border.all(color: VetoPalette.border),
                        ),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(color: isUser ? Colors.white : VetoPalette.text),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: widget.code == 'he' ? 'הקלד הודעה...' : widget.code == 'ru' ? 'Введите сообщение...' : 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: VetoPalette.primary),
                    onPressed: _send,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}