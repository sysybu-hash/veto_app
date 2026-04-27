// ============================================================
//  call_entry_screen.dart — Routes /call to chat (WebRTC room
//  signaling only) or to Agora for real-time audio/video.
// ============================================================

import 'package:flutter/material.dart';

import 'agora_call_screen.dart';
import 'call_screen.dart';

/// Named route `/call` entry: [CallScreen] handles `callType == 'chat'`;
/// audio/video use [AgoraCallScreen].
class CallEntryScreen extends StatelessWidget {
  const CallEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/veto_screen');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    var ct = args['callType']?.toString() ?? 'video';
    if (ct == 'webrtc') ct = 'video';

    if (ct == 'chat') {
      return const CallScreen();
    }

    final roomId = args['roomId']?.toString() ?? '';
    if (roomId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/veto_screen');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return AgoraCallScreen(
      channelId: roomId,
      token: args['agoraToken']?.toString() ?? '',
      peerLabel: args['peerName']?.toString() ?? 'Peer',
      wantVideo: ct == 'video',
      socketRole: args['role']?.toString() ?? 'user',
    );
  }
}
