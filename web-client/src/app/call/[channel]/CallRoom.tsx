"use client";

import AgoraRTC, {
  AgoraRTCProvider,
  LocalVideoTrack,
  RemoteUser,
  useJoin,
  useLocalCameraTrack,
  useLocalMicrophoneTrack,
  usePublish,
  useRTCClient,
  useRemoteUsers,
} from "agora-rtc-react";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useState } from "react";
import { getPublicAgoraAppId } from "@/lib/env";
import { getSocket } from "@/lib/socketClient";
import { useEmergencyStore } from "@/store/useEmergencyStore";

function CallInner({ channel }: { channel: string }) {
  const router = useRouter();
  const client = useRTCClient();
  const session = useEmergencyStore((s) => s.sessionReady);
  const clearCallSession = useEmergencyStore((s) => s.clearCallSession);

  const [micOn, setMicOn] = useState(true);
  const [cameraOn, setCameraOn] = useState(true);
  const [joinError, setJoinError] = useState<string | null>(null);

  const appId = getPublicAgoraAppId();
  const videoSession = session != null && session.callType !== "audio";

  const { localMicrophoneTrack } = useLocalMicrophoneTrack(true);
  const { localCameraTrack, error: camErr } = useLocalCameraTrack(videoSession);

  useEffect(() => {
    if (camErr && videoSession) {
      setJoinError(camErr.message);
    }
  }, [camErr, videoSession]);

  const joinArgs = useMemo(() => {
    if (!session || !appId) return null;
    return {
      appid: appId,
      channel: session.channelId,
      token: session.token,
      uid: session.uid,
    };
  }, [appId, session]);

  const ready =
    !!joinArgs &&
    joinArgs.channel === channel &&
    !!localMicrophoneTrack &&
    (!videoSession || !!localCameraTrack);

  const { isConnected, error: joinHookError } = useJoin(
    joinArgs ?? { appid: "", channel: "", token: null },
    Boolean(joinArgs && ready),
    client,
  );

  useEffect(() => {
    if (joinHookError) {
      setJoinError(joinHookError.message);
    }
  }, [joinHookError]);

  usePublish(
    [localMicrophoneTrack, videoSession ? localCameraTrack : null],
    ready && isConnected,
    client,
  );

  useEffect(() => {
    localMicrophoneTrack?.setEnabled(micOn);
  }, [localMicrophoneTrack, micOn]);

  useEffect(() => {
    localCameraTrack?.setEnabled(cameraOn);
  }, [localCameraTrack, cameraOn]);

  const remoteUsers = useRemoteUsers();

  useEffect(() => {
    if (!client || !channel) return;
    const onExpire = () => {
      try {
        getSocket().emit("call-renew-token", { roomId: channel });
      } catch {
        /* not logged in / no socket */
      }
    };
    client.on("token-privilege-will-expire", onExpire);
    return () => {
      client.off("token-privilege-will-expire", onExpire);
    };
  }, [client, channel]);

  useEffect(() => {
    const sock = (() => {
      try {
        return getSocket();
      } catch {
        return null;
      }
    })();
    if (!sock || !client) return;

    const handler = async (raw: unknown) => {
      if (!raw || typeof raw !== "object") return;
      const p = raw as { roomId?: string; agoraToken?: string };
      if (p.roomId !== channel || !p.agoraToken) return;
      try {
        await client.renewToken(p.agoraToken);
      } catch (e) {
        console.warn("[call] renewToken failed:", e);
      }
    };

    sock.on("call-token-renewed", handler);
    return () => {
      sock.off("call-token-renewed", handler);
    };
  }, [channel, client]);

  const leave = useCallback(async () => {
    try {
      localCameraTrack?.close();
      localMicrophoneTrack?.close();
    } catch {
      /* ignore */
    }
    try {
      await client?.leave();
    } catch {
      /* ignore */
    }
    clearCallSession();
    router.replace("/hub");
  }, [
    clearCallSession,
    client,
    localCameraTrack,
    localMicrophoneTrack,
    router,
  ]);

  if (!session || session.channelId !== channel) {
    return (
      <div className="flex min-h-full flex-col items-center justify-center gap-4 px-6 text-center">
        <p className="text-slate-200">No active call session for this channel.</p>
        <button
          type="button"
          onClick={() => router.replace("/hub")}
          className="rounded-xl bg-white/10 px-4 py-2 text-sm font-medium text-white hover:bg-white/15"
        >
          Back to hub
        </button>
      </div>
    );
  }

  if (!appId) {
    return (
      <div className="flex min-h-full flex-col items-center justify-center px-6 text-center text-amber-200">
        Missing <code className="rounded bg-black/30 px-1">NEXT_PUBLIC_AGORA_APP_ID</code>.
      </div>
    );
  }

  const remote = remoteUsers[0];

  return (
    <div className="relative flex min-h-full flex-col bg-black">
      <div className="relative flex-1 overflow-hidden">
        {remote ? (
          <RemoteUser
            user={remote}
            playVideo={videoSession}
            playAudio
            className="h-full w-full [&_video]:h-full [&_video]:w-full [&_video]:object-cover"
          />
        ) : (
          <div className="flex h-full items-center justify-center text-slate-400">
            {isConnected ? "Waiting for the lawyer to join…" : "Connecting…"}
          </div>
        )}

        {videoSession && localCameraTrack && (
          <div className="absolute right-3 top-3 z-10 h-28 w-20 overflow-hidden rounded-lg border border-white/20 shadow-lg sm:h-36 sm:w-28">
            <LocalVideoTrack
              track={localCameraTrack}
              play={cameraOn}
              className="h-full w-full object-cover"
            />
          </div>
        )}
      </div>

      {joinError && (
        <div className="absolute left-2 right-2 top-2 z-20 rounded-lg bg-red-950/90 px-3 py-2 text-center text-xs text-red-100">
          {joinError}
        </div>
      )}

      <div className="absolute bottom-0 left-0 right-0 z-20 border-t border-white/10 bg-black/70 px-4 py-3 backdrop-blur-md">
        <div className="mx-auto flex max-w-md items-center justify-center gap-3">
          <button
            type="button"
            aria-pressed={!micOn}
            onClick={() => setMicOn((v) => !v)}
            className={`rounded-full px-4 py-2 text-sm font-medium ${
              micOn ? "bg-white/15 text-white" : "bg-amber-600 text-white"
            }`}
          >
            {micOn ? "Mute" : "Unmute"}
          </button>
          {videoSession && (
            <button
              type="button"
              aria-pressed={!cameraOn}
              onClick={() => setCameraOn((v) => !v)}
              className={`rounded-full px-4 py-2 text-sm font-medium ${
                cameraOn ? "bg-white/15 text-white" : "bg-amber-600 text-white"
              }`}
            >
              {cameraOn ? "Camera off" : "Camera on"}
            </button>
          )}
          <button
            type="button"
            onClick={() => void leave()}
            className="rounded-full bg-red-600 px-5 py-2 text-sm font-semibold text-white hover:bg-red-500"
          >
            End
          </button>
        </div>
      </div>
    </div>
  );
}

export default function CallRoom({ channel }: { channel: string }) {
  const client = useMemo(
    () => AgoraRTC.createClient({ mode: "rtc", codec: "vp8" }),
    [],
  );

  return (
    <AgoraRTCProvider client={client}>
      <CallInner channel={channel} />
    </AgoraRTCProvider>
  );
}
