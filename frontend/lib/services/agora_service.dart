// ============================================================
//  agora_service.dart — Agora RTC engine wrapper (ChangeNotifier)
//  App ID: [kAgoraAppIdPlaceholder] (from Agora Console).
// ============================================================

import 'dart:developer' as developer;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

/// Agora project App ID (from Agora Console).
const String kAgoraAppIdPlaceholder = 'b40f2355783a4ccca027a91d0d7100ca';

class AgoraService extends ChangeNotifier {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _joined = false;
  String? _activeChannelId;
  String? _errorMessage;

  RtcEngine? get engine => _engine;
  int? get remoteUid => _remoteUid;
  bool get joined => _joined;
  String? get activeChannelId => _activeChannelId;
  String? get errorMessage => _errorMessage;

  /// Creates and initializes [RtcEngine] once. Safe to call again if already ready.
  Future<void> initializeEngine() async {
    if (_engine != null) return;
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: kAgoraAppIdPlaceholder,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _joined = true;
            _errorMessage = null;
            notifyListeners();
          },
          onUserJoined:
              (RtcConnection connection, int remoteUid, int elapsed) {
            _remoteUid = remoteUid;
            notifyListeners();
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            if (_remoteUid == remoteUid) {
              _remoteUid = null;
              notifyListeners();
            }
          },
          onError: (ErrorCodeType err, String msg) {
            _errorMessage = '$err: $msg';
            notifyListeners();
          },
        ),
      );

      await _engine!.enableVideo();
      await _engine!.startPreview();
      notifyListeners();
    } catch (e, st) {
      _errorMessage = e.toString();
      developer.log(
        'initializeEngine',
        name: 'VETO.Agora',
        error: e,
        stackTrace: st,
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Joins a channel. [token] can be empty only if your project allows App ID join (dev).
  Future<void> joinChannel({
    required String channelId,
    String token = '',
    int uid = 0,
  }) async {
    await initializeEngine();
    final eng = _engine;
    if (eng == null) return;

    _activeChannelId = channelId;
    _errorMessage = null;
    notifyListeners();

    await eng.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  /// Leaves the current channel (engine stays alive for reuse).
  Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
    } catch (e, st) {
      developer.log('leaveChannel', name: 'VETO.Agora', error: e, stackTrace: st);
    } finally {
      _joined = false;
      _remoteUid = null;
      _activeChannelId = null;
      notifyListeners();
    }
  }

  /// Leaves channel and releases native engine (call when screen closes).
  Future<void> leaveChannelAndRelease() async {
    await leaveChannel();
    try {
      await _engine?.release();
    } catch (e, st) {
      developer.log(
        'release',
        name: 'VETO.Agora',
        error: e,
        stackTrace: st,
      );
    } finally {
      _engine = null;
      notifyListeners();
    }
  }
}
