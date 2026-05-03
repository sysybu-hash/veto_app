import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import 'v26_call_side_panel.dart';
import 'v26_call_stage.dart';

class V26CallChatSheet extends StatelessWidget {
  const V26CallChatSheet({
    super.key,
    required this.language,
    required this.lines,
    required this.onSend,
    this.captionLines = const <String>[],
    this.captionListening = false,
    this.captionError,
    this.onToggleCaption,
  });

  final String language;
  final List<CallChatLine> lines;
  final ValueChanged<String> onSend;
  final List<String> captionLines;
  final bool captionListening;
  final String? captionError;
  final VoidCallback? onToggleCaption;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.80,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: V26CallGlassPanel(
            padding: const EdgeInsets.only(top: 10),
            borderRadius: 24,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: V26.gold.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(V26.rPill),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: V26CallSidePanel(
                    language: language,
                    lines: lines,
                    onSend: onSend,
                    captionLines: captionLines,
                    captionListening: captionListening,
                    captionError: captionError,
                    onToggleCaption: onToggleCaption,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
