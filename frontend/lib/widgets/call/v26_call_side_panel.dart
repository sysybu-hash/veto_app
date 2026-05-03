// ============================================================
//  v26_call_side_panel.dart — Chat + Caption side panel that sits
//  next to the video stage on wide screens and as a bottom drawer
//  on phones.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/veto_2026.dart';
import 'call_i18n.dart';

/// A single chat line rendered in the panel.
class CallChatLine {
  CallChatLine({required this.text, required this.mine, DateTime? sentAt})
      : sentAt = sentAt ?? DateTime.now();
  final String text;
  final bool mine;
  final DateTime sentAt;
}

class V26CallSidePanel extends StatefulWidget {
  const V26CallSidePanel({
    super.key,
    required this.language,
    required this.lines,
    required this.onSend,
    this.captionLines = const <String>[],
    this.captionListening = false,
    this.captionError,
    this.onToggleCaption,
    this.backgroundColor,
  });

  final String language;
  final List<CallChatLine> lines;
  final ValueChanged<String> onSend;
  final List<String> captionLines;
  final bool captionListening;
  final String? captionError;
  final VoidCallback? onToggleCaption;
  final Color? backgroundColor;

  @override
  State<V26CallSidePanel> createState() => _V26CallSidePanelState();
}

class _V26CallSidePanelState extends State<V26CallSidePanel>
    with TickerProviderStateMixin {
  late final TabController _tab;
  final _chatCtrl = TextEditingController();
  final _chatScroll = ScrollController();
  int _previousLineCount = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _previousLineCount = widget.lines.length;
  }

  @override
  void didUpdateWidget(V26CallSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length > _previousLineCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScroll.hasClients) {
          _chatScroll.animateTo(
            _chatScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _previousLineCount = widget.lines.length;
  }

  @override
  void dispose() {
    _tab.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _chatCtrl.text.trim();
    if (t.isEmpty) return;
    widget.onSend(t);
    _chatCtrl.clear();
  }

  String _formatTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backgroundColor ?? V26.surface,
      child: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: V26.navy600,
            unselectedLabelColor: V26.ink300,
            indicatorColor: V26.gold,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontFamily: V26.sans,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: CallI18n.tabChat.t(widget.language)),
              Tab(text: CallI18n.tabCaption.t(widget.language)),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: V26.hairline),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildChat(),
                _buildCaption(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: widget.lines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      CallI18n.chatEmpty.t(widget.language),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: V26.ink300,
                        fontFamily: V26.sans,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _chatScroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.lines.length,
                  itemBuilder: (_, i) {
                    final line = widget.lines[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: line.mine
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxWidth: 260),
                          decoration: BoxDecoration(
                            color: line.mine ? V26.navy600 : V26.surface,
                            border: line.mine
                                ? null
                                : Border.all(color: V26.hairline),
                            borderRadius: BorderRadiusDirectional.only(
                              topStart: const Radius.circular(14),
                              topEnd: const Radius.circular(14),
                              bottomStart: line.mine
                                  ? const Radius.circular(14)
                                  : const Radius.circular(4),
                              bottomEnd: line.mine
                                  ? const Radius.circular(4)
                                  : const Radius.circular(14),
                            ),
                            boxShadow: V26.shadow1,
                          ),
                          child: Column(
                            crossAxisAlignment: line.mine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                line.text,
                                style: TextStyle(
                                  color: line.mine ? Colors.white : V26.ink900,
                                  fontFamily: V26.sans,
                                  fontSize: 13.5,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTime(line.sentAt),
                                style: TextStyle(
                                  color: line.mine
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : V26.ink300,
                                  fontFamily: V26.sans,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: V26.hairline)),
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(color: V26.ink900, fontFamily: V26.sans),
                  decoration: InputDecoration(
                    hintText: CallI18n.messagePlaceholder.t(widget.language),
                    hintStyle: const TextStyle(color: V26.ink300, fontFamily: V26.sans),
                    filled: true,
                    fillColor: V26.paper2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: V26.navy600,
                  foregroundColor: Colors.white,
                ),
                tooltip: CallI18n.sendMessage.t(widget.language),
                onPressed: _send,
                icon: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaption() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (kIsWeb)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: V26.warnSoft,
              borderRadius: BorderRadius.circular(V26.rSm),
              border: Border.all(color: V26.warn.withValues(alpha: 0.3)),
            ),
            child: Text(
              CallI18n.captionWebNotice.t(widget.language),
              style: const TextStyle(
                color: V26.warn,
                fontFamily: V26.sans,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (kIsWeb) const SizedBox(height: 12),
        if (!kIsWeb)
          FilledButton.icon(
            onPressed: widget.onToggleCaption,
            style: FilledButton.styleFrom(
              backgroundColor:
                  widget.captionListening ? V26.emerg : V26.paper2,
              foregroundColor:
                  widget.captionListening ? Colors.white : V26.ink700,
              minimumSize: const Size.fromHeight(44),
            ),
            icon: Icon(
              widget.captionListening ? Icons.stop_circle : Icons.mic,
            ),
            label: Text(
              widget.captionListening
                  ? CallI18n.captionStop.t(widget.language)
                  : CallI18n.captionStart.t(widget.language),
              style: const TextStyle(fontFamily: V26.sans),
            ),
          ),
        if (widget.captionError != null) ...[
          const SizedBox(height: 10),
          Text(
            widget.captionError!,
            style: const TextStyle(
              color: V26.emerg,
              fontSize: 12,
              fontFamily: V26.sans,
            ),
          ),
        ],
        const SizedBox(height: 14),
        for (final line in widget.captionLines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '• $line',
              style: const TextStyle(
                color: V26.ink900,
                fontFamily: V26.sans,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}
