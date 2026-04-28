// ============================================================
//  call_entry_screen.dart — Routes /call: text chat or Agora A/V.
// ============================================================

import 'package:flutter/material.dart';

import 'call_session_screen.dart';
import 'call_screen.dart';

/// Named route `/call` entry: [CallScreen] handles `callType == 'chat'`;
/// audio/video use [CallSessionScreen] (Agora + in-call chat + optional caption).
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

    int parseAgoraUid(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return CallSessionScreen(
      channelId: roomId,
      eventId: args['eventId']?.toString() ?? roomId,
      language: args['language']?.toString() ?? 'he',
      token: args['agoraToken']?.toString() ?? '',
      agoraUid: parseAgoraUid(args['agoraUid']),
      peerLabel: args['peerName']?.toString() ?? 'Peer',
      wantVideo: ct == 'video',
      socketRole: args['role']?.toString() ?? 'user',
    );
  }
}
