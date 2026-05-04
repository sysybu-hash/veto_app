import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'call_types.dart';

/// Maps Agora SDK [ErrorCodeType] to app-level failure categories.
CallFailureKind classifyAgoraErrorCode(ErrorCodeType error) {
  switch (error) {
    case ErrorCodeType.errInvalidToken:
    case ErrorCodeType.errInvalidAppId:
    case ErrorCodeType.errInvalidUserId:
      return CallFailureKind.tokenInvalid;
    case ErrorCodeType.errTokenExpired:
      return CallFailureKind.tokenExpired;
    case ErrorCodeType.errNoPermission:
    case ErrorCodeType.errVdmCameraNotAuthorized:
      return CallFailureKind.permissionDenied;
    case ErrorCodeType.errConnectionLost:
    case ErrorCodeType.errConnectionInterrupted:
    case ErrorCodeType.errNetDown:
    case ErrorCodeType.errBindSocket:
      return CallFailureKind.networkLost;
    case ErrorCodeType.errJoinChannelRejected:
    case ErrorCodeType.errAlreadyInUse:
      return CallFailureKind.uidConflict;
    case ErrorCodeType.errNotReady:
    case ErrorCodeType.errTimedout:
    case ErrorCodeType.errFailed:
      return CallFailureKind.connectionFailed;
    default:
      return CallFailureKind.unknown;
  }
}

/// Whether an [onError] callback may be resolved by leave + fresh token + re-join.
bool isJoinRecoverableFromSdkError(ErrorCodeType error, String message) {
  final upper = message.toUpperCase();
  if (upper.contains('UID_CONFLICT') ||
      upper.contains('SAME_UID') ||
      upper.contains('JOIN_CHANNEL_REJECTED')) {
    return true;
  }
  switch (error) {
    case ErrorCodeType.errJoinChannelRejected:
    case ErrorCodeType.errInvalidUserId:
    case ErrorCodeType.errAlreadyInUse:
      return true;
    default:
      return false;
  }
}

/// Connection drop reasons that warrant credential refresh before rejoin.
bool isRecoverableConnectionReason(ConnectionChangedReasonType reason) {
  switch (reason) {
    case ConnectionChangedReasonType.connectionChangedSameUidLogin:
    case ConnectionChangedReasonType.connectionChangedRejectedByServer:
    case ConnectionChangedReasonType.connectionChangedInvalidToken:
    case ConnectionChangedReasonType.connectionChangedTokenExpired:
      return true;
    default:
      return false;
  }
}
