import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_glass_system.dart';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SizedBox(
          width: 400,
          height: 500,
          child: VetoGlassBlur(
            borderRadius: 24,
            sigma: VetoGlassTokens.blurSigma,
            fill: VetoGlassTokens.glassFillStrong,
            borderColor: VetoGlassTokens.glassBorderBright,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: VetoGlassTokens.neonCyan),
                      const SizedBox(width: 8),
                      Text(
                        widget.code == 'he' ? 'סייען VETO' : widget.code == 'ru' ? 'Ассистент VETO' : 'VETO Assistant',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.2,
                          color: VetoGlassTokens.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: VetoGlassTokens.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: Color(0x28FFFFFF)),
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
                              gradient: isUser ? VetoGlassTokens.neonButton : null,
                              color: isUser ? null : VetoGlassTokens.glassFill,
                              borderRadius: BorderRadius.circular(14),
                              border: isUser ? null : Border.all(color: VetoGlassTokens.glassBorder),
                            ),
                            child: Text(
                              m['text'] ?? '',
                              style: TextStyle(
                                color: isUser ? Colors.white : VetoGlassTokens.textPrimary,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: VetoGlassTokens.neonCyan),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: const TextStyle(color: VetoGlassTokens.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: widget.code == 'he' ? 'הקלד הודעה...' : widget.code == 'ru' ? 'Введите сообщение...' : 'Type a message...',
                            hintStyle: const TextStyle(color: VetoGlassTokens.textMuted),
                            filled: true,
                            fillColor: VetoGlassTokens.glassFill,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: VetoGlassTokens.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: VetoGlassTokens.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: VetoGlassTokens.neonCyan.withValues(alpha: 0.7), width: 1.2),
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _send,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: VetoGlassTokens.neonButton,
                            boxShadow: [
                              BoxShadow(
                                color: VetoGlassTokens.neonCyan.withValues(alpha: 0.25),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}