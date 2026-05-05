import 'package:flutter/material.dart';

import '../core/theme/veto_2026.dart';

/// Small pulsing dot for “Live” / active session indicators.
class LivePulseDot extends StatefulWidget {
  const LivePulseDot({super.key, required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<LivePulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.45),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

/// AI assistant bubble styled like [2026/communication.html] `.ai-card`.
class GeminiAiMessageCard extends StatelessWidget {
  const GeminiAiMessageCard({
    super.key,
    required this.text,
    required this.langKey,
    this.hadNativeAudio = false,
    this.maxWidthFactor = 0.78,
  });

  final String text;
  final String langKey;
  final bool hadNativeAudio;
  final double maxWidthFactor;

  String get _brandLine {
    switch (langKey) {
      case 'ru':
        return 'GEMINI · ЮРИДИЧЕСКИЙ ПОМОЩНИК';
      case 'en':
        return 'GEMINI · LEGAL ASSISTANT';
      default:
        return 'GEMINI · עוזר משפטי';
    }
  }

  String get _audioHint {
    switch (langKey) {
      case 'ru':
        return 'Голосовой ответ';
      case 'en':
        return 'Voice reply';
      default:
        return 'תשובה קולית';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width * maxWidthFactor;
    return Semantics(
      label: '$_brandLine. $text',
      child: Container(
        width: w,
        constraints: BoxConstraints(maxWidth: w),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4F8FF),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE7FB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E69E7), Color(0xFF5B8BF0)],
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _brandLine,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF1B3A66),
                          ),
                        ),
                      ),
                      if (hadNativeAudio)
                        Tooltip(
                          message: _audioHint,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_up_rounded, size: 14, color: V26.navy500.withValues(alpha: 0.9)),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: V26.ok.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  langKey == 'he'
                                      ? 'LIVE'
                                      : langKey == 'ru'
                                          ? 'LIVE'
                                          : 'LIVE',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: V26.ok,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: V26.ink900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing / processing indicator matching Gemini AI card chrome.
class GeminiAiTypingBubble extends StatelessWidget {
  const GeminiAiTypingBubble({
    super.key,
    required this.label,
    this.maxWidthFactor = 0.78,
    this.alignment = Alignment.centerRight,
  });

  final String label;
  final double maxWidthFactor;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width * maxWidthFactor;
    return Semantics(
      label: label,
      child: Align(
        alignment: alignment,
        child: Container(
          width: w,
          constraints: BoxConstraints(maxWidth: w),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4F8FF), Colors.white],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE7FB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: V26.hairline,
                  valueColor: AlwaysStoppedAnimation<Color>(V26.navy500.withValues(alpha: 0.85)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: V26.ink500,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
