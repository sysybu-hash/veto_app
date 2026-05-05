// ============================================================
//  call_i18n.dart — Call UI strings from ARB (AppLocalizations).
// ============================================================

import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Strings for the Agora call stack; keys mirror `callUi*` in ARB.
class CallL10n {
  CallL10n._();

  static AppLocalizations _of(BuildContext context) =>
      AppLocalizations.of(context)!;

  static String badgeConnecting(BuildContext c) =>
      _of(c).callUiBadgeConnecting;
  static String findingLawyer(BuildContext c) => _of(c).callUiFindingLawyer;
  static String connectingNearby(BuildContext c) =>
      _of(c).callUiConnectingNearby;
  static String connectingDetails(BuildContext c) =>
      _of(c).callUiConnectingDetails;
  static String cancelRequest(BuildContext c) => _of(c).callUiCancelRequest;
  static String incomingBadge(BuildContext c) => _of(c).callUiIncomingBadge;
  static String incomingUnknown(BuildContext c) =>
      _of(c).callUiIncomingUnknown;
  static String incomingCaseDetails(BuildContext c) =>
      _of(c).callUiIncomingCaseDetails;
  static String incomingDecline(BuildContext c) =>
      _of(c).callUiIncomingDecline;
  static String incomingChatFirst(BuildContext c) =>
      _of(c).callUiIncomingChatFirst;
  static String incomingAccept(BuildContext c) =>
      _of(c).callUiIncomingAccept;
  static String encryptedBadge(BuildContext c) =>
      _of(c).callUiEncryptedBadge;
  static String connectedEncrypted(BuildContext c) =>
      _of(c).callUiConnectedEncrypted;
  static String aes256Footer(BuildContext c) => _of(c).callUiAes256Footer;
  static String recordingShort(BuildContext c) =>
      _of(c).callUiRecordingShort;
  static String recordingPill(BuildContext c) => _of(c).callUiRecordingPill;
  static String muteMic(BuildContext c) => _of(c).callUiMuteMic;
  static String unmuteMic(BuildContext c) => _of(c).callUiUnmuteMic;
  static String speaker(BuildContext c) => _of(c).callUiSpeaker;
  static String camera(BuildContext c) => _of(c).callUiCamera;
  static String cameraOff(BuildContext c) => _of(c).callUiCameraOff;
  static String flipCamera(BuildContext c) => _of(c).callUiFlipCamera;
  static String screenShare(BuildContext c) => _of(c).callUiScreenShare;
  static String stopScreenShare(BuildContext c) =>
      _of(c).callUiStopScreenShare;
  static String noiseSuppression(BuildContext c) =>
      _of(c).callUiNoiseSuppression;
  static String openChat(BuildContext c) => _of(c).callUiOpenChat;
  static String endCall(BuildContext c) => _of(c).callUiEndCall;
  static String waitingForPeer(BuildContext c) =>
      _of(c).callUiWaitingForPeer;
  static String waitingForPeerVideo(BuildContext c) =>
      _of(c).callUiWaitingForPeerVideo;
  static String cameraLabel(BuildContext c) => _of(c).callUiCameraLabel;
  static String cameraOffLabel(BuildContext c) =>
      _of(c).callUiCameraOffLabel;
  static String voiceHeader(BuildContext c) => _of(c).callUiVoiceHeader;
  static String tabChat(BuildContext c) => _of(c).callUiTabChat;
  static String tabCaption(BuildContext c) => _of(c).callUiTabCaption;
  static String sendMessage(BuildContext c) => _of(c).callUiSendMessage;
  static String messagePlaceholder(BuildContext c) =>
      _of(c).callUiMessagePlaceholder;
  static String chatEmpty(BuildContext c) => _of(c).callUiChatEmpty;
  static String captionWebNotice(BuildContext c) =>
      _of(c).callUiCaptionWebNotice;
  static String captionStart(BuildContext c) => _of(c).callUiCaptionStart;
  static String captionStop(BuildContext c) => _of(c).callUiCaptionStop;
  static String errorTitle(BuildContext c) => _of(c).callUiErrorTitle;
  static String errorPermission(BuildContext c) =>
      _of(c).callUiErrorPermission;
  static String errorTokenInvalid(BuildContext c) =>
      _of(c).callUiErrorTokenInvalid;
  static String errorTokenExpired(BuildContext c) =>
      _of(c).callUiErrorTokenExpired;
  static String errorNetwork(BuildContext c) => _of(c).callUiErrorNetwork;
  static String errorMedia(BuildContext c) => _of(c).callUiErrorMedia;
  static String errorGeneric(BuildContext c) => _of(c).callUiErrorGeneric;
  static String errorUidConflict(BuildContext c) =>
      _of(c).callUiErrorUidConflict;
  static String webStartCall(BuildContext c) => _of(c).callUiWebStartCall;
  static String webStartCallHint(BuildContext c) =>
      _of(c).callUiWebStartCallHint;
  static String webInsecureContext(BuildContext c) =>
      _of(c).callUiWebInsecureContext;
  static String errorRetry(BuildContext c) => _of(c).callUiErrorRetry;
  static String errorExit(BuildContext c) => _of(c).callUiErrorExit;
  static String vaultSaveTitle(BuildContext c) =>
      _of(c).callUiVaultSaveTitle;
  static String vaultSaveSubtitle(BuildContext c) =>
      _of(c).callUiVaultSaveSubtitle;
  static String vaultSaveMediaOnly(BuildContext c) =>
      _of(c).callUiVaultSaveMediaOnly;
  static String vaultSaveMediaAndTranscript(BuildContext c) =>
      _of(c).callUiVaultSaveMediaAndTranscript;
  static String vaultSaveChatOnly(BuildContext c) =>
      _of(c).callUiVaultSaveChatOnly;
  static String vaultSaveSkip(BuildContext c) =>
      _of(c).callUiVaultSaveSkip;
  static String vaultWebNoLocalRecording(BuildContext c) =>
      _of(c).callUiVaultWebNoLocalRecording;
  static String vaultNothingToSave(BuildContext c) =>
      _of(c).callUiVaultNothingToSave;
  static String qualityExcellent(BuildContext c) =>
      _of(c).callUiQualityExcellent;
  static String qualityGood(BuildContext c) => _of(c).callUiQualityGood;
  static String qualityFair(BuildContext c) => _of(c).callUiQualityFair;
  static String qualityPoor(BuildContext c) => _of(c).callUiQualityPoor;
  static String qualityVeryPoor(BuildContext c) =>
      _of(c).callUiQualityVeryPoor;
  static String leaveCallTitle(BuildContext c) => _of(c).callUiLeaveCallTitle;
  static String leaveCallBody(BuildContext c) => _of(c).callUiLeaveCallBody;
}
