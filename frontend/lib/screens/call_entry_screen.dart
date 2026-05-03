// ============================================================
//  call_entry_screen.dart — Routes /call: text chat or Agora A/V.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigator.dart';
import '../core/i18n/app_language.dart';
import '../core/theme/veto_2026.dart';
import '../services/call_route_args_storage.dart';
import 'call_session_screen.dart';
import 'call_screen.dart';

String _redirectHomeMessage(BuildContext context) {
  try {
    final code = context.read<AppLanguageController>().code;
    switch (AppLanguage.normalize(code)) {
      case AppLanguage.hebrew:
        return 'מעבירים לבית…';
      case AppLanguage.russian:
        return 'Возврат на главную…';
      default:
        return 'Returning home…';
    }
  } catch (_) {
    return 'Returning home…';
  }
}

String _tapHomeLabel(BuildContext context) {
  try {
    switch (AppLanguage.normalize(context.read<AppLanguageController>().code)) {
      case AppLanguage.hebrew:
        return 'חזרה לדף הבית';
      case AppLanguage.russian:
        return 'На главную';
      default:
        return 'Back to home';
    }
  } catch (_) {
    return 'Back to home';
  }
}

/// Shown while redirecting away from /call (missing args). Never rely on a single
/// [Navigator] callback on Web — retry timer + manual button.
class _RedirectHomeGate extends StatefulWidget {
  const _RedirectHomeGate({required this.message});

  final String message;

  @override
  State<_RedirectHomeGate> createState() => _RedirectHomeGateState();
}

class _RedirectHomeGateState extends State<_RedirectHomeGate> {
  bool _showManual = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showManual = true);
    });
  }

  void _goHome() {
    final root = vetoRootNavigatorKey.currentState;
    if (root != null) {
      root.pushReplacementNamed('/veto_screen');
    } else if (mounted) {
      Navigator.of(context).pushReplacementNamed('/veto_screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V26.paper,
      body: V26Backdrop(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: V26.navy600),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: V26.sans,
                    color: V26.ink500,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_showManual) ...[
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _goHome,
                    child: Text(
                      _tapHomeLabel(context),
                      style: const TextStyle(
                        fontFamily: V26.sans,
                        color: V26.navy600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Named route `/call` entry: [CallScreen] handles `callType == 'chat'`;
/// audio/video use [CallSessionScreen] (Agora + in-call chat + optional caption).
class CallEntryScreen extends StatefulWidget {
  const CallEntryScreen({super.key});

  @override
  State<CallEntryScreen> createState() => _CallEntryScreenState();
}

class _CallEntryScreenState extends State<CallEntryScreen> {
  bool _scheduledRedirect = false;
  Timer? _redirectRetry;

  @override
  void dispose() {
    _redirectRetry?.cancel();
    super.dispose();
  }

  void _scheduleRedirectHome() {
    if (_scheduledRedirect) return;
    _scheduledRedirect = true;

    void go() {
      final root = vetoRootNavigatorKey.currentState;
      if (root != null) {
        root.pushReplacementNamed('/veto_screen');
      } else if (mounted) {
        Navigator.of(context).pushReplacementNamed('/veto_screen');
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => go());
    _redirectRetry?.cancel();
    _redirectRetry = Timer(const Duration(seconds: 2), go);
  }

  @override
  Widget build(BuildContext context) {
    var args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    args ??= callRouteArgsStorageRead();

    if (args == null) {
      _scheduleRedirectHome();
      return _RedirectHomeGate(message: _redirectHomeMessage(context));
    }

    var ct = args['callType']?.toString() ?? 'video';
    if (ct == 'webrtc') ct = 'video';

    if (ct == 'chat') {
      return const CallScreen();
    }

    final roomId = args['roomId']?.toString() ?? '';
    if (roomId.isEmpty) {
      _scheduleRedirectHome();
      return _RedirectHomeGate(message: _redirectHomeMessage(context));
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
