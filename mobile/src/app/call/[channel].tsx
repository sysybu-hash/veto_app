import { useLocalSearchParams, useRouter } from "expo-router";
import { useCallback, useEffect, useRef, useState } from "react";
import { Alert, Pressable, Text, View } from "react-native";
import createAgoraRtcEngine, {
  ChannelMediaOptions,
  ChannelProfileType,
  ClientRoleType,
  RenderModeType,
  RtcSurfaceView,
  VideoCanvas,
  VideoMirrorModeType,
  VideoSourceType,
} from "react-native-agora";

import { agoraAppId } from "@/constants/config";
import {
  emitCallRenewToken,
  emitJoinCallRoom,
  subscribeCallTokenRenewed,
} from "@/services/socketManager";
import { useCallSessionStore } from "@/store/callSessionStore";

export default function CallScreen() {
  const router = useRouter();
  const { channel } = useLocalSearchParams<{ channel: string }>();
  const roomId = Array.isArray(channel) ? channel[0] : channel;

  const session = useCallSessionStore((s) => s.session);
  const clearSession = useCallback(() => useCallSessionStore.getState().setSession(null), []);

  const engineRef = useRef(createAgoraRtcEngine());
  const [remoteUid, setRemoteUid] = useState<number | null>(null);
  const [muted, setMuted] = useState(false);
  const [videoDisabled, setVideoDisabled] = useState(false);

  useEffect(() => {
    if (!agoraAppId) {
      Alert.alert("Agora", "חסר EXPO_PUBLIC_AGORA_APP_ID");
      return;
    }
    if (!session || session.roomId !== roomId) {
      return;
    }

    const eng = engineRef.current;

    eng.initialize({ appId: agoraAppId });
    eng.setChannelProfile(ChannelProfileType.ChannelProfileLiveBroadcasting);

    const handler = {
      onJoinChannelSuccess: () => {
        emitJoinCallRoom(
          session.roomId,
          session.callType === "chat" ? "chat" : session.callType,
        );
      },
      onUserJoined: (_connection: unknown, uid: number) => {
        setRemoteUid(uid);
      },
      onUserOffline: (_connection: unknown, _uid: number) => {
        setRemoteUid(null);
      },
      onError: (_err: number, msg: string) => {
        Alert.alert("Agora", msg ?? "שגיאה");
      },
      onTokenPrivilegeWillExpire: () => {
        emitCallRenewToken(session.roomId);
      },
    };

    eng.registerEventHandler(handler);

    const renewHandler = (data: { roomId: string; agoraToken: string }) => {
      if (data.roomId === session.roomId) {
        eng.renewToken(data.agoraToken);
      }
    };
    const offRenew = subscribeCallTokenRenewed(renewHandler);

    eng.enableVideo();
    eng.startPreview();

    const localCanvas = new VideoCanvas();
    localCanvas.uid = session.agoraUid;
    localCanvas.renderMode = RenderModeType.RenderModeHidden;
    localCanvas.mirrorMode = VideoMirrorModeType.VideoMirrorModeEnabled;
    localCanvas.sourceType = VideoSourceType.VideoSourceCamera;
    eng.setupLocalVideo(localCanvas);

    const opts = new ChannelMediaOptions();
    opts.clientRoleType = ClientRoleType.ClientRoleBroadcaster;
    opts.channelProfile = ChannelProfileType.ChannelProfileLiveBroadcasting;
    opts.publishCameraTrack = true;
    opts.publishMicrophoneTrack = true;

    eng.joinChannel(session.agoraToken, session.channelId, session.agoraUid, opts);

    return () => {
      offRenew();
      eng.unregisterEventHandler(handler);
      eng.leaveChannel();
      eng.release();
      clearSession();
    };
  }, [session, roomId, clearSession]);

  if (!session || session.roomId !== roomId) {
    return (
      <View className="flex-1 items-center justify-center bg-background px-6">
        <Text className="text-center text-legal-slate">
          שיחה לא זמינה. חזור למסך הבית ונסה שוב.
        </Text>
        <Pressable className="mt-4 rounded-xl bg-primary px-6 py-3" onPress={() => router.back()}>
          <Text className="font-semibold text-white">חזרה</Text>
        </Pressable>
      </View>
    );
  }

  const localUid = session.agoraUid;

  function toggleMute() {
    const next = !muted;
    setMuted(next);
    engineRef.current.muteLocalAudioStream(next);
  }

  function toggleCam() {
    const next = !videoDisabled;
    setVideoDisabled(next);
    engineRef.current.muteLocalVideoStream(next);
  }

  function endCall() {
    engineRef.current.leaveChannel();
    clearSession();
    router.back();
  }

  return (
    <View className="flex-1 bg-black">
      <View className="flex-1">
        {remoteUid !== null ? (
          <RtcSurfaceView
            canvas={{ uid: remoteUid, renderMode: RenderModeType.RenderModeHidden }}
            className="h-full w-full"
          />
        ) : (
          <View className="flex-1 items-center justify-center">
            <Text className="text-white/80">ממתין לצד שני…</Text>
          </View>
        )}
      </View>

      <View className="absolute right-4 top-16 h-36 w-28 overflow-hidden rounded-xl border-2 border-white/40 shadow-lg">
        <RtcSurfaceView
          canvas={{
            uid: localUid,
            renderMode: RenderModeType.RenderModeHidden,
            mirrorMode: VideoMirrorModeType.VideoMirrorModeEnabled,
          }}
          className="h-full w-full"
        />
      </View>

      <View className="absolute bottom-0 left-0 right-0 flex-row items-center justify-center gap-4 bg-black/70 pb-10 pt-4">
        <Pressable
          onPress={toggleMute}
          className={`rounded-full px-5 py-3 ${muted ? "bg-amber-600" : "bg-white/20"}`}
        >
          <Text className="font-semibold text-white">{muted ? "בטל השתקה" : "השתק"}</Text>
        </Pressable>
        <Pressable
          onPress={toggleCam}
          className={`rounded-full px-5 py-3 ${videoDisabled ? "bg-amber-600" : "bg-white/20"}`}
        >
          <Text className="font-semibold text-white">{videoDisabled ? "הפעל מצלמה" : "כבה מצלמה"}</Text>
        </Pressable>
        <Pressable onPress={endCall} className="rounded-full bg-red-600 px-5 py-3">
          <Text className="font-semibold text-white">סיים</Text>
        </Pressable>
      </View>
    </View>
  );
}
