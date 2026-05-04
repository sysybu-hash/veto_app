enum CallUiPhase {
  idle,
  incoming,
  /// Web: user must tap once so camera/mic run in a secure gesture context.
  awaitingMediaGesture,
  connecting,
  active,
  reconnecting,
  ended,
  error,
}

enum CallFailureKind {
  none,
  permissionDenied,
  tokenInvalid,
  tokenExpired,
  networkLost,
  connectionFailed,
  mediaUnavailable,
  /// Duplicate UID / join rejected — recover with fresh token + leave/rejoin.
  uidConflict,
  unknown,
}

class CallFailure {
  const CallFailure(this.kind, this.message);
  final CallFailureKind kind;
  final String message;
}

