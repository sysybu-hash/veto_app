import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/veto_2026.dart';
import '../../screens/in_call_speech.dart';
import '../../services/call_route_args_storage.dart';
import '../../services/vault_save_queue.dart';
import '../../widgets/call/call_i18n.dart';
import 'call_args.dart';
import 'call_session_controller.dart';
import 'call_web_media.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CallSessionController? _controller;
  late final InCallSpeech _speech;
  final TextEditingController _messageController = TextEditingController();
  bool _navigatedAway = false;
  bool _queuedArtifacts = false;
  bool _webMediaInsecure = false;
  String _webInsecureLang = 'he';

  @override
  void initState() {
    super.initState();
    _speech = createInCallSpeech(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final raw = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? data;
    if (raw is Map<String, dynamic>) data = raw;
    data ??= callRouteArgsStorageRead();

    final args = CallArgs.tryParse(data);
    if (!mounted) return;
    if (args == null) {
      Navigator.of(context).pushReplacementNamed('/veto_screen');
      return;
    }

    if (kIsWeb && !isCallMediaSecureContext()) {
      if (!mounted) return;
      setState(() {
        _webMediaInsecure = true;
        _webInsecureLang = args.language;
      });
      return;
    }

    _speech.setLanguageCode(args.language);
    final controller = CallSessionController(args: args);
    controller.addListener(_onControllerChanged);
    setState(() => _controller = controller);
    await controller.boot();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final controller = _controller;
    if (controller?.phase == CallUiPhase.ended && !_navigatedAway) {
      _queuePostCallArtifacts(controller!);
      _navigatedAway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
    setState(() {});
  }

  void _queuePostCallArtifacts(CallSessionController controller) {
    if (_queuedArtifacts) return;
    _queuedArtifacts = true;
    final args = controller.args;
    if (args.eventId.isEmpty) return;
    try {
      final queue = context.read<VaultSaveQueue>();
      if (args.chatOnly) {
        final transcript = controller.chatLines
            .map((line) => '${line.mine ? 'Me' : args.peerLabel}: ${line.text}')
            .join('\n');
        queue.enqueueChatTranscript(
          eventId: args.eventId,
          transcript: transcript,
          roomLabel: args.peerLabel,
        );
      } else if (controller.durationSec >= 1) {
        queue.enqueueAgoraRecordingTranscript(
          eventId: args.eventId,
          language: args.language,
          roomLabel: args.peerLabel,
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onControllerChanged);
      controller.dispose();
    }
    _messageController.dispose();
    unawaited(_speech.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final args = controller?.args;
    final direction = (args?.isRtl ?? true) ? TextDirection.rtl : TextDirection.ltr;
    return PopScope(
      canPop: controller == null ||
          _webMediaInsecure ||
          controller.phase == CallUiPhase.incoming ||
          controller.phase == CallUiPhase.awaitingMediaGesture ||
          controller.phase == CallUiPhase.error ||
          controller.phase == CallUiPhase.ended,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_confirmEnd());
      },
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          backgroundColor: V26.callBgBottom,
          body: SafeArea(
            child: _webMediaInsecure
                ? _WebInsecureMediaView(
                    language: _webInsecureLang,
                    onBack: () => Navigator.of(context).pop(),
                  )
                : controller == null
                    ? const Center(child: CircularProgressIndicator(color: V26.gold))
                    : _buildContent(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CallSessionController controller) {
    switch (controller.phase) {
      case CallUiPhase.idle:
      case CallUiPhase.connecting:
        return _ConnectingView(controller: controller);
      case CallUiPhase.awaitingMediaGesture:
        return _WebGestureStartView(
          controller: controller,
          onStart: () => unawaited(controller.beginConnectAfterUserGesture()),
        );
      case CallUiPhase.incoming:
        return _IncomingView(
          controller: controller,
          onAccept: () => unawaited(controller.acceptIncoming()),
          onDecline: () => unawaited(controller.declineIncoming()),
        );
      case CallUiPhase.active:
      case CallUiPhase.reconnecting:
        return _ActiveView(
          controller: controller,
          speech: _speech,
          messageController: _messageController,
          onSend: _sendMessage,
          onEnd: () => unawaited(_confirmEnd()),
        );
      case CallUiPhase.error:
        return _ErrorView(
          controller: controller,
          onRetry: () => unawaited(controller.retry()),
          onExit: () => unawaited(controller.endCall()),
        );
      case CallUiPhase.ended:
        return const Center(child: CircularProgressIndicator(color: V26.gold));
    }
  }

  void _sendMessage() {
    final text = _messageController.text;
    _messageController.clear();
    _controller?.sendChat(text);
  }

  Future<void> _confirmEnd() async {
    final controller = _controller;
    if (controller == null) return;
    final lang = controller.args.language;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: V26.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            switch (lang) {
              'he' => 'לצאת מהשיחה?',
              'ru' => 'Покинуть звонок?',
              _ => 'Leave call?',
            },
            style: const TextStyle(
              color: V26.ink900,
              fontFamily: V26.serif,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            switch (lang) {
              'he' => 'השיחה תיסגר לשני הצדדים.',
              'ru' => 'Сессия завершится для обеих сторон.',
              _ => 'The session will end for both sides.',
            },
            style: const TextStyle(color: V26.ink500, fontFamily: V26.sans),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                switch (lang) {
                  'he' => 'ביטול',
                  'ru' => 'Отмена',
                  _ => 'Cancel',
                },
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: V26.emerg),
              onPressed: () => Navigator.pop(context, true),
              child: Text(CallI18n.endCall.t(lang)),
            ),
          ],
        );
      },
    );
    if (ok == true) await controller.endCall();
  }
}

class _CallScaffold extends StatelessWidget {
  const _CallScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [V26.callBgTop, V26.callBgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _CallGlow()),
          child,
        ],
      ),
    );
  }
}

class _CallGlow extends StatelessWidget {
  const _CallGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CallGlowPainter(),
      ),
    );
  }
}

class _CallGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    blob(Offset(size.width * .92, -size.height * .10), size.width * .7, V26.navy500);
    blob(Offset(size.width * .08, size.height * .92), size.width * .55, V26.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WebInsecureMediaView extends StatelessWidget {
  const _WebInsecureMediaView({required this.language, required this.onBack});

  final String language;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _CallScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: V26.goldSoft, size: 56),
                const SizedBox(height: 16),
                Text(
                  CallI18n.webInsecureContext.t(language),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: V26.sans,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: V26.navy500),
                  onPressed: onBack,
                  child: Text(CallI18n.errorExit.t(language)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebGestureStartView extends StatelessWidget {
  const _WebGestureStartView({
    required this.controller,
    required this.onStart,
  });

  final CallSessionController controller;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final lang = controller.args.language;
    return _CallScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app_rounded, color: V26.goldSoft, size: 64),
                const SizedBox(height: 20),
                Text(
                  CallI18n.webStartCallHint.t(lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: V26.sans,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: V26.ok,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  onPressed: onStart,
                  child: Text(CallI18n.webStartCall.t(lang)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({required this.controller});
  final CallSessionController controller;

  @override
  Widget build(BuildContext context) {
    final lang = controller.args.language;
    return _CallScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [V26.emerg, V26.emerg2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: V26.shadowEmerg,
                  ),
                  child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 54),
                ),
                const SizedBox(height: 24),
                Text(
                  CallI18n.badgeConnecting.t(lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: V26.serif,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  CallI18n.connectingDetails.t(lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: V26.sans,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                const CircularProgressIndicator(color: V26.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingView extends StatelessWidget {
  const _IncomingView({
    required this.controller,
    required this.onAccept,
    required this.onDecline,
  });

  final CallSessionController controller;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final args = controller.args;
    final lang = args.language;
    return _CallScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: V26.callGlass,
                border: Border.all(color: V26.callGoldHair),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .34),
                    blurRadius: 48,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CallI18n.incomingBadge.t(lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: V26.goldSoft,
                      fontFamily: V26.sans,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    args.peerLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: V26.serif,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (args.caseSummary.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      args.caseSummary,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: V26.sans,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: V26.callGoldHair),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: onDecline,
                          child: Text(CallI18n.incomingDecline.t(lang)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: V26.ok,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: onAccept,
                          child: Text(CallI18n.incomingAccept.t(lang)),
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

class _ActiveView extends StatelessWidget {
  const _ActiveView({
    required this.controller,
    required this.speech,
    required this.messageController,
    required this.onSend,
    required this.onEnd,
  });

  final CallSessionController controller;
  final InCallSpeech speech;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final args = controller.args;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isWide = w >= 900;
        final isCompact = w < 600;
        final hPad = isCompact ? 10.0 : 14.0;
        return _CallScaffold(
          child: Column(
            children: [
              _TopBar(controller: controller, compact: isCompact),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 10),
                  child: args.chatOnly
                      ? _ChatPanel(
                          controller: controller,
                          speech: speech,
                          messageController: messageController,
                          onSend: onSend,
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _VideoOrVoiceStage(
                                controller: controller,
                                layoutWidth: w - hPad * 2,
                              ),
                            ),
                            if (isWide) ...[
                              const SizedBox(width: 14),
                              SizedBox(
                                width: 340,
                                child: _ChatPanel(
                                  controller: controller,
                                  speech: speech,
                                  messageController: messageController,
                                  onSend: onSend,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              _Toolbar(
                controller: controller,
                onChat: isWide
                    ? null
                    : () => _openChatSheet(
                          context,
                          controller,
                          speech,
                          messageController,
                          onSend,
                        ),
                onEnd: onEnd,
                compact: isCompact,
              ),
              const SizedBox(height: 8),
              Text(
                CallI18n.aes256Footer.t(args.language),
                style: const TextStyle(
                  color: V26.goldSoft,
                  fontFamily: V26.sans,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _openChatSheet(
    BuildContext context,
    CallSessionController controller,
    InCallSpeech speech,
    TextEditingController messageController,
    VoidCallback onSend,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: FractionallySizedBox(
            heightFactor: .78,
            child: _ChatPanel(
              controller: controller,
              speech: speech,
              messageController: messageController,
              onSend: onSend,
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, this.compact = false});
  final CallSessionController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final args = controller.args;
    final pad = compact ? 10.0 : 14.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 10, pad, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: V26.callGlass,
          border: Border.all(color: V26.callGoldHairSoft),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Text(
              'VETO',
              style: TextStyle(
                color: V26.goldSoft,
                fontFamily: V26.serif,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    args.peerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: V26.sans,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.phase == CallUiPhase.reconnecting
                        ? CallI18n.errorNetwork.t(args.language)
                        : CallI18n.connectedEncrypted.t(args.language),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontFamily: V26.sans,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _Pill(
              label: _formatDuration(controller.durationSec),
              color: V26.callRecBg,
              textColor: Colors.white,
              small: compact,
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              _Pill(
                label: _qualityLabel(controller.quality, args.language),
                color: V26.callGlassSoft,
                textColor: V26.goldSoft,
                small: compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.textColor,
    this.small = false,
  });
  final String label;
  final Color color;
  final Color textColor;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 5 : 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontFamily: V26.sans,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VideoOrVoiceStage extends StatelessWidget {
  const _VideoOrVoiceStage({required this.controller, this.layoutWidth = 720});
  final CallSessionController controller;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    if (!controller.args.wantVideo) {
      return _VoiceStage(controller: controller, layoutWidth: layoutWidth);
    }
    return _VideoStage(controller: controller, layoutWidth: layoutWidth);
  }
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({required this.controller, this.layoutWidth = 720});
  final CallSessionController controller;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;
    final remoteUid = controller.remoteUid;
    final hasRemote = engine != null && remoteUid != null && remoteUid != 0;
    final canShowLocal = engine != null && !controller.videoMuted;
    // renderModeAdaptive is deprecated in Agora and breaks layout on some web + RTL setups.
    const renderMode = RenderModeType.renderModeHidden;
    final viewPad = MediaQuery.paddingOf(context);
    final localUid = controller.joinedAgoraUid;
    final rtcConn = RtcConnection(
      channelId: controller.args.channelId,
      localUid: localUid > 0 ? localUid : null,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: viewPad.left > 0 ? 4 : 0,
        right: viewPad.right > 0 ? 4 : 0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(V26.callRadiusVideo),
          border: Border.all(color: V26.callGoldHair),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .38),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(V26.callRadiusVideo - 1),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasRemote)
                  AgoraVideoView(
                    key: ValueKey('remote-$remoteUid'),
                    controller: VideoViewController.remote(
                      rtcEngine: engine,
                      canvas: VideoCanvas(
                        uid: remoteUid,
                        renderMode: renderMode,
                      ),
                      connection: rtcConn,
                    ),
                  )
                else if (canShowLocal)
                  AgoraVideoView(
                    key: const ValueKey('local-full-until-remote'),
                    controller: VideoViewController(
                      rtcEngine: engine,
                      canvas: const VideoCanvas(
                        uid: 0,
                        renderMode: renderMode,
                        mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
                      ),
                    ),
                  )
                else
                  _VideoPlaceholder(controller: controller),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .18),
                        Colors.transparent,
                        Colors.black.withValues(alpha: .18),
                      ],
                    ),
                  ),
                ),
                if (hasRemote && !controller.remoteVideoReady)
                  Center(
                    child: _Pill(
                      label: CallI18n.waitingForPeerVideo.t(controller.args.language),
                      color: V26.callGlass,
                      textColor: V26.goldSoft,
                    ),
                  ),
                if (hasRemote && canShowLocal)
                  Positioned(
                    top: 12 + viewPad.top * 0.25,
                    right: 12,
                    child: _LocalPip(engine: engine, layoutWidth: layoutWidth),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalPip extends StatelessWidget {
  const _LocalPip({required this.engine, this.layoutWidth = 720});
  final RtcEngine engine;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    final narrow = layoutWidth < 420;
    final pipW = kIsWeb ? (narrow ? 128.0 : 154.0) : (narrow ? 108.0 : 126.0);
    final pipH = kIsWeb ? (narrow ? 96.0 : 116.0) : (narrow ? 82.0 : 96.0);
    return Container(
      width: pipW,
      height: pipH,
      decoration: BoxDecoration(
        color: V26.navy700,
        borderRadius: BorderRadius.circular(V26.callRadiusPip),
        border: Border.all(color: V26.callGoldHair),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AgoraVideoView(
        key: const ValueKey('local-pip-agora'),
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(
            uid: 0,
            renderMode: RenderModeType.renderModeHidden,
            mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
          ),
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.controller});
  final CallSessionController controller;

  @override
  Widget build(BuildContext context) {
    final lang = controller.args.language;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [V26.navy700, V26.callBgBottom],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, color: Colors.white70, size: 86),
          const SizedBox(height: 14),
          Text(
            controller.videoMuted
                ? CallI18n.cameraOffLabel.t(lang)
                : CallI18n.waitingForPeer.t(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: V26.sans,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceStage extends StatelessWidget {
  const _VoiceStage({required this.controller, this.layoutWidth = 720});
  final CallSessionController controller;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    final maxCard = layoutWidth < 400 ? layoutWidth - 24.0 : 360.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCard),
        child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(layoutWidth < 380 ? 20 : 28),
        decoration: BoxDecoration(
          color: V26.callGlass,
          border: Border.all(color: V26.callGoldHair),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq_rounded, color: V26.goldSoft, size: 80),
            const SizedBox(height: 18),
            Text(
              CallI18n.voiceHeader.t(controller.args.language),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: V26.serif,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              controller.args.peerLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontFamily: V26.sans),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.onEnd,
    this.onChat,
    this.compact = false,
  });

  final CallSessionController controller;
  final VoidCallback onEnd;
  final VoidCallback? onChat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? 10.0 : 14.0;
    final btn = compact ? 44.0 : 48.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: V26.callGlass,
          border: Border.all(color: V26.callGoldHairSoft),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _RoundButton(
              icon: Icons.call_end,
              danger: true,
              onPressed: onEnd,
              tooltip: CallI18n.endCall.t(controller.args.language),
              diameter: btn,
            ),
            _RoundButton(
              icon: controller.micMuted ? Icons.mic_off : Icons.mic,
              active: !controller.micMuted,
              onPressed: () => unawaited(controller.setMicMuted(!controller.micMuted)),
              tooltip: controller.micMuted
                  ? CallI18n.unmuteMic.t(controller.args.language)
                  : CallI18n.muteMic.t(controller.args.language),
              diameter: btn,
            ),
            if (controller.args.wantVideo)
              _RoundButton(
                icon: controller.videoMuted ? Icons.videocam_off : Icons.videocam,
                active: !controller.videoMuted,
                onPressed: () => unawaited(controller.setVideoMuted(!controller.videoMuted)),
                tooltip: controller.videoMuted
                    ? CallI18n.camera.t(controller.args.language)
                    : CallI18n.cameraOff.t(controller.args.language),
                diameter: btn,
              ),
            if (!kIsWeb && controller.args.wantVideo)
              _RoundButton(
                icon: Icons.flip_camera_ios,
                onPressed: () => unawaited(controller.switchCamera()),
                tooltip: CallI18n.flipCamera.t(controller.args.language),
                diameter: btn,
              ),
            if (!kIsWeb)
              _RoundButton(
                icon: controller.speakerOn ? Icons.volume_up : Icons.hearing,
                active: controller.speakerOn,
                onPressed: () => unawaited(controller.setSpeakerOn(!controller.speakerOn)),
                tooltip: CallI18n.speaker.t(controller.args.language),
                diameter: btn,
              ),
            if (kIsWeb && controller.args.wantVideo)
              _RoundButton(
                icon: controller.screenSharing ? Icons.stop_screen_share : Icons.screen_share,
                active: controller.screenSharing,
                onPressed: () => unawaited(controller.toggleScreenShare()),
                tooltip: controller.screenSharing
                    ? CallI18n.stopScreenShare.t(controller.args.language)
                    : CallI18n.screenShare.t(controller.args.language),
                diameter: btn,
              ),
            _RoundButton(
              icon: Icons.noise_control_off,
              active: controller.noiseSuppression,
              onPressed: () => unawaited(
                controller.setNoiseSuppression(!controller.noiseSuppression),
              ),
              tooltip: CallI18n.noiseSuppression.t(controller.args.language),
              diameter: btn,
            ),
            if (onChat != null)
              _RoundButton(
                icon: Icons.chat_bubble_outline,
                onPressed: onChat,
                tooltip: CallI18n.openChat.t(controller.args.language),
                diameter: btn,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.active = false,
    this.danger = false,
    this.diameter = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool active;
  final bool danger;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? V26.callDangerRed
        : active
            ? V26.gold.withValues(alpha: .26)
            : Colors.white.withValues(alpha: .08);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: V26.callGoldHair),
          ),
          child: Icon(icon, color: Colors.white, size: diameter < 46 ? 20 : 22),
        ),
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.controller,
    required this.speech,
    required this.messageController,
    required this.onSend,
  });

  final CallSessionController controller;
  final InCallSpeech speech;
  final TextEditingController messageController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final lang = controller.args.language;
    return Container(
      decoration: BoxDecoration(
        color: V26.callGlass,
        border: Border.all(color: V26.callGoldHairSoft),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    CallI18n.tabChat.t(lang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: V26.sans,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => unawaited(speech.toggle()),
                  icon: Icon(
                    speech.listening ? Icons.closed_caption_disabled : Icons.closed_caption,
                    size: 18,
                  ),
                  label: Text(
                    speech.listening
                        ? CallI18n.captionStop.t(lang)
                        : CallI18n.captionStart.t(lang),
                  ),
                  style: TextButton.styleFrom(foregroundColor: V26.goldSoft),
                ),
              ],
            ),
          ),
          const Divider(color: V26.callGoldHairSoft, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                if (controller.chatLines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      CallI18n.chatEmpty.t(lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontFamily: V26.sans),
                    ),
                  ),
                for (final line in controller.chatLines)
                  Align(
                    alignment: line.mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 260),
                      decoration: BoxDecoration(
                        color: line.mine
                            ? V26.navy500.withValues(alpha: .7)
                            : Colors.white.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        line.text,
                        style: const TextStyle(color: Colors.white, fontFamily: V26.sans),
                      ),
                    ),
                  ),
                if (speech.lines.isNotEmpty || speech.partial.isNotEmpty || speech.error != null)
                  const Divider(color: V26.callGoldHairSoft),
                for (final line in speech.lines)
                  Text(
                    line,
                    style: const TextStyle(color: V26.goldSoft, fontFamily: V26.sans),
                  ),
                if (speech.partial.isNotEmpty)
                  Text(
                    speech.partial,
                    style: const TextStyle(color: Colors.white54, fontFamily: V26.sans),
                  ),
                if (speech.error != null)
                  Text(
                    kIsWeb ? CallI18n.captionWebNotice.t(lang) : speech.error!,
                    style: const TextStyle(color: Colors.white54, fontFamily: V26.sans),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontFamily: V26.sans),
                    decoration: InputDecoration(
                      hintText: CallI18n.messagePlaceholder.t(lang),
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: V26.goldDeep),
                  onPressed: onSend,
                  child: Text(CallI18n.sendMessage.t(lang)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.controller,
    required this.onRetry,
    required this.onExit,
  });

  final CallSessionController controller;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final lang = controller.args.language;
    final failure = controller.failure;
    return _CallScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: V26.callGlass,
                border: Border.all(color: V26.callGoldHair),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: V26.callDangerRed, size: 58),
                  const SizedBox(height: 16),
                  Text(
                    CallI18n.errorTitle.t(lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: V26.serif,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _errorText(failure, lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontFamily: V26.sans),
                  ),
                  if ((failure?.message ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      failure!.message,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontFamily: V26.sans,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: V26.callGoldHair),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: onExit,
                          child: Text(CallI18n.errorExit.t(lang)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: V26.navy500,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: onRetry,
                          child: Text(CallI18n.errorRetry.t(lang)),
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

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

String _qualityLabel(CallNetworkQuality quality, String lang) {
  final worst = quality.worst;
  if (worst <= 0) return 'LTE';
  if (worst <= 2) return CallI18n.qualityExcellent.t(lang);
  if (worst == 3) return CallI18n.qualityGood.t(lang);
  if (worst == 4) return CallI18n.qualityFair.t(lang);
  if (worst == 5) return CallI18n.qualityPoor.t(lang);
  return CallI18n.qualityVeryPoor.t(lang);
}

String _errorText(CallFailure? failure, String lang) {
  switch (failure?.kind) {
    case CallFailureKind.permissionDenied:
      return CallI18n.errorPermission.t(lang);
    case CallFailureKind.tokenInvalid:
      return CallI18n.errorTokenInvalid.t(lang);
    case CallFailureKind.tokenExpired:
      return CallI18n.errorTokenExpired.t(lang);
    case CallFailureKind.networkLost:
      return CallI18n.errorNetwork.t(lang);
    case CallFailureKind.mediaUnavailable:
      return CallI18n.errorMedia.t(lang);
    case CallFailureKind.uidConflict:
      return CallI18n.errorUidConflict.t(lang);
    case CallFailureKind.connectionFailed:
    case CallFailureKind.unknown:
    case CallFailureKind.none:
    case null:
      return CallI18n.errorGeneric.t(lang);
  }
}
