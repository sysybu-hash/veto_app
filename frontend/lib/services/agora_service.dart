// ============================================================
//  agora_service.dart — Agora RTC engine wrapper (ChangeNotifier)
//  App ID: [kAgoraAppIdPlaceholder] (from Agora Console).
// ============================================================

import 'dart:async' show unawaited;
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
  /// Web: [startPreview] after join only (see Agora web issues — preview before join can hard-crash the tab).
  bool _webPreviewAfterJoin = false;

  RtcEngine? get engine => _engine;
  int? get remoteUid => _remoteUid;
  bool get joined => _joined;
  String? get activeChannelId => _activeChannelId;
  String? get errorMessage => _errorMessage;

  /// Creates and initializes [RtcEngine] once. Safe to call again if already ready.
  Future<void> initializeEngine({bool enableVideoTrack = true}) async {
    if (_engine != null) return;
    RtcEngine? eng;
    try {
      eng = createAgoraRtcEngine();
      _engine = eng;
      await eng.initialize(
        const RtcEngineContext(
          appId: kAgoraAppIdPlaceholder,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      eng.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _joined = true;
            _errorMessage = null;
            if (_webPreviewAfterJoin) {
              _webPreviewAfterJoin = false;
              unawaited(_webStartPreviewSafe());
            }
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
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state, ConnectionChangedReasonType reason) {
            if (state == ConnectionStateType.connectionStateFailed) {
              _errorMessage =
                  'Agora connection failed ($reason). Check token, App ID, and network.';
              notifyListeners();
            }
          },
        ),
      );

      if (enableVideoTrack) {
        await eng.enableVideo();
        // On iOS/Android, preview before join is normal. On **web**, starting preview
        // before join has been reported to hang or kill the tab; we start preview in
        // [onJoinChannelSuccess] when [_webPreviewAfterJoin] is set.
        if (!kIsWeb) {
          await eng.startPreview();
        }
      } else {
        await eng.disableVideo();
      }
      notifyListeners();
    } catch (e, st) {
      _errorMessage = e.toString();
      developer.log(
        'initializeEngine',
        name: 'VETO.Agora',
        error: e,
        stackTrace: st,
      );
      // Singleton engine must not stay half-initialized; next call would return early and break join.
      try {
        if (eng != null) {
          await eng.release();
        }
      } catch (_) {}
      _engine = null;
      eng = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Joins a channel.
  /// - [token] + [uid] from server must match (see [buildRtcTokenForUid] in backend).
  /// - For dev without certificate, [token] is empty and [uid] should be 0.
  Future<void> _webStartPreviewSafe() async {
    final e = _engine;
    if (e == null) return;
    if (kIsWeb) {
      // ignore: avoid_print
      print('[VETO][Agora] startPreview (web, after join)');
    }
    try {
      await e.startPreview();
      notifyListeners();
    } catch (err, st) {
      _errorMessage = 'שגיאת מצלמה (דפדפן): $err';
      developer.log('web startPreview', name: 'VETO.Agora', error: err, stackTrace: st);
      notifyListeners();
    }
  }

  Future<void> joinChannel({
    required String channelId,
    String token = '',
    int uid = 0,
    bool publishVideo = true,
  }) async {
    await initializeEngine(enableVideoTrack: publishVideo);
    final eng = _engine;
    if (eng == null) return;

    _activeChannelId = channelId;
    _errorMessage = null;
    if (kIsWeb && publishVideo) {
      _webPreviewAfterJoin = true;
    }
    notifyListeners();

    try {
      await eng.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: publishVideo,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      _webPreviewAfterJoin = false;
      rethrow;
    }
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
