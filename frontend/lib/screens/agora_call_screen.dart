// ============================================================
//  agora_call_screen.dart — Agora video call (PiP + fullscreen)
//  Style aligned with [CallScreen]; logic uses [AgoraService] only.
// ============================================================

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme/veto_theme.dart';
import '../services/agora_service.dart';

class AgoraCallScreen extends StatefulWidget {
  const AgoraCallScreen({
    super.key,
    required this.channelId,
    this.token = '',
    this.peerLabel = 'Lawyer',
  });

  final String channelId;
  final String token;
  final String peerLabel;

  @override
  State<AgoraCallScreen> createState() => _AgoraCallScreenState();
}

class _AgoraCallScreenState extends State<AgoraCallScreen> {
  late final AgoraService _agora;
  bool _starting = true;
  String? _startError;

  @override
  void initState() {
    super.initState();
    _agora = AgoraService();
    _agora.addListener(_onAgora);
    unawaited(_bootstrap());
  }

  void _onAgora() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    try {
      if (!kIsWeb) {
        await Future.wait([
          Permission.microphone.request(),
          Permission.camera.request(),
        ]);
      }
      await _agora.joinChannel(
        channelId: widget.channelId,
        token: widget.token,
      );
    } catch (e) {
      _startError = e.toString();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _endCall() async {
    await _agora.leaveChannelAndRelease();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _agora.removeListener(_onAgora);
    unawaited(() async {
      await _agora.leaveChannelAndRelease();
      _agora.dispose();
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eng = _agora.engine;
    final remote = _agora.remoteUid;
    final channel = widget.channelId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: VetoDecorations.gradientBg(),
          ),
          if (_starting)
            const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            )
          else if (_startError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _startError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontFamily: 'Heebo'),
                ),
              ),
            )
          else if (eng != null) ...[
            Positioned.fill(
              child: remote != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: eng,
                        canvas: VideoCanvas(uid: remote),
                        connection: RtcConnection(channelId: channel),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_search, color: Colors.white54, size: 56),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for ${widget.peerLabel}…',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Heebo',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 100,
              right: 16,
              width: 100,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: VetoColors.surface,
                    border: Border.all(color: VetoColors.border),
                  ),
                  child: _agora.joined
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: eng,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.videocam_outlined, color: VetoColors.silver),
                        ),
                ),
              ),
            ),
          ],
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: VetoColors.vetoRedSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: VetoColors.vetoRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield, color: VetoColors.vetoRed, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'VETO',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: VetoColors.vetoRed,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.peerLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Heebo',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_agora.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                        child: Text(
                          _agora.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange.shade200,
                            fontSize: 12,
                            fontFamily: 'Heebo',
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _starting ? null : _endCall,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VetoColors.vetoRed,
                          boxShadow: VetoDecorations.vetoGlow(intensity: 0.8),
                        ),
                        child: const Icon(Icons.call_end, color: VetoColors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'End Call',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
