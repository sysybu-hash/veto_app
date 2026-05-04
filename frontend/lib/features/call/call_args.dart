class CallArgs {
  const CallArgs({
    required this.channelId,
    required this.eventId,
    required this.language,
    required this.token,
    required this.agoraUid,
    required this.peerLabel,
    required this.peerSpecialization,
    required this.caseSummary,
    required this.distanceLabel,
    required this.wantVideo,
    required this.chatOnly,
    required this.socketRole,
    required this.isIncoming,
  });

  final String channelId;
  final String eventId;
  final String language;
  final String token;
  final int agoraUid;
  final String peerLabel;
  final String? peerSpecialization;
  final String caseSummary;
  final String? distanceLabel;
  final bool wantVideo;
  final bool chatOnly;
  final String socketRole;
  final bool isIncoming;

  bool get isRtl => language == 'he' || language == 'ar';

  static CallArgs? tryParse(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final roomId = raw['roomId']?.toString() ?? '';
    if (roomId.isEmpty) return null;

    var callType = raw['callType']?.toString() ?? 'video';
    if (callType == 'webrtc') callType = 'video';

    int parseUid(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return CallArgs(
      channelId: roomId,
      eventId: raw['eventId']?.toString() ?? roomId,
      language: raw['language']?.toString() ?? 'he',
      token: raw['agoraToken']?.toString() ?? '',
      agoraUid: parseUid(raw['agoraUid']),
      peerLabel: raw['peerName']?.toString() ?? 'Peer',
      peerSpecialization: raw['peerSpecialization']?.toString(),
      caseSummary: raw['caseSummary']?.toString() ?? '',
      distanceLabel: raw['distanceLabel']?.toString(),
      wantVideo: callType == 'video',
      chatOnly: callType == 'chat',
      socketRole: raw['role']?.toString() ?? 'user',
      isIncoming: raw['mode']?.toString() == 'incoming',
    );
  }
}
