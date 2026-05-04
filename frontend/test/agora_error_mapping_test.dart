import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veto/features/call/agora_error_mapping.dart';
import 'package:veto/features/call/call_types.dart';

void main() {
  test('classifyAgoraErrorCode maps token and join errors', () {
    expect(classifyAgoraErrorCode(ErrorCodeType.errTokenExpired), CallFailureKind.tokenExpired);
    expect(classifyAgoraErrorCode(ErrorCodeType.errInvalidToken), CallFailureKind.tokenInvalid);
    expect(classifyAgoraErrorCode(ErrorCodeType.errJoinChannelRejected), CallFailureKind.uidConflict);
    expect(classifyAgoraErrorCode(ErrorCodeType.errAlreadyInUse), CallFailureKind.uidConflict);
  });

  test('isJoinRecoverableFromSdkError detects message substrings', () {
    expect(
      isJoinRecoverableFromSdkError(ErrorCodeType.errFailed, 'UID_CONFLICT from server'),
      isTrue,
    );
    expect(
      isJoinRecoverableFromSdkError(ErrorCodeType.errJoinChannelRejected, ''),
      isTrue,
    );
    expect(
      isJoinRecoverableFromSdkError(ErrorCodeType.errOk, 'generic'),
      isFalse,
    );
  });

  test('isRecoverableConnectionReason includes token and same-uid', () {
    expect(
      isRecoverableConnectionReason(ConnectionChangedReasonType.connectionChangedSameUidLogin),
      isTrue,
    );
    expect(
      isRecoverableConnectionReason(ConnectionChangedReasonType.connectionChangedTokenExpired),
      isTrue,
    );
    expect(
      isRecoverableConnectionReason(ConnectionChangedReasonType.connectionChangedLost),
      isFalse,
    );
  });
}
