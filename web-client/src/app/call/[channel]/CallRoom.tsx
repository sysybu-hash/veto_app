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
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { connectSocket, getSocket } from "@/lib/socketClient";
import { useEmergencyStore } from "@/store/useEmergencyStore";

type CallChatMessage = {
  id: string;
  text: string;
  mine: boolean;
};

function CallInner({ channel }: { channel: string }) {
  const router = useRouter();
  const { t } = useTranslation();
  const client = useRTCClient();
  const session = useEmergencyStore((s) => s.sessionReady);
  const clearCallSession = useEmergencyStore((s) => s.clearCallSession);

  const [micOn, setMicOn] = useState(true);
  const [cameraOn, setCameraOn] = useState(true);
  const [chatDraft, setChatDraft] = useState("");
  const [chatMessages, setChatMessages] = useState<CallChatMessage[]>([]);
  const [roomStatus, setRoomStatus] = useState<string | null>(null);
  const appId = getPublicAgoraAppId();
  const chatOnly = session?.callType === "chat";
  const videoSession = session != null && session.callType === "video";

  const { localMicrophoneTrack } = useLocalMicrophoneTrack(!chatOnly);
  const { localCameraTrack, error: camErr } = useLocalCameraTrack(videoSession);

  const joinArgs = useMemo(() => {
    if (!session || !appId || chatOnly) return null;
    return {
      appid: appId,
      channel: session.channelId,
      token: session.token,
      uid: session.uid,
    };
  }, [appId, chatOnly, session]);

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

  const joinError =
    joinHookError?.message ??
    (camErr && videoSession ? camErr.message : null);

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
    if (!session || session.channelId !== channel) return;
    const sock = connectSocket();
    const roomId = session.eventId || channel;

    const onReady = () => setRoomStatus(t("call.chatReady"));
    const onTimeout = () => setRoomStatus(t("call.peerTimeout"));
    const onEnded = () => setRoomStatus(t("call.peerEnded"));
    const onError = (raw: unknown) => {
      const msg =
        raw &&
        typeof raw === "object" &&
        "message" in raw &&
        typeof (raw as { message?: unknown }).message === "string"
          ? (raw as { message: string }).message
          : t("call.callError");
      setRoomStatus(msg);
    };
    const onChat = (raw: unknown) => {
      if (!raw || typeof raw !== "object") return;
      const text = (raw as { text?: unknown }).text;
      if (typeof text !== "string" || !text.trim()) return;
      setChatMessages((prev) => [
        ...prev,
        { id: `${Date.now()}-${prev.length}`, text: text.trim(), mine: false },
      ]);
    };

    sock.emit("join-call-room", { roomId, callType: session.callType });
    sock.on("chat-ready", onReady);
    sock.on("call-timeout", onTimeout);
    sock.on("call-ended", onEnded);
    sock.on("call-error", onError);
    sock.on("call-chat-message", onChat);

    return () => {
      sock.emit("call-ended", { roomId });
      sock.off("chat-ready", onReady);
      sock.off("call-timeout", onTimeout);
      sock.off("call-ended", onEnded);
      sock.off("call-error", onError);
      sock.off("call-chat-message", onChat);
      sock.emit("leave-call-room", { roomId });
    };
  }, [channel, session, t]);

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
    try {
      getSocket().emit("call-ended", { roomId: session?.eventId || channel });
    } catch {
      /* ignore */
    }
    clearCallSession();
    router.replace("/hub");
  }, [
    channel,
    clearCallSession,
    client,
    localCameraTrack,
    localMicrophoneTrack,
    router,
    session,
  ]);

  const sendCallChat = useCallback(() => {
    const text = chatDraft.trim();
    if (!session || !text) return;
    const roomId = session.eventId || channel;
    try {
      getSocket().emit("call-chat-message", { roomId, text });
      setChatMessages((prev) => [
        ...prev,
        { id: `${Date.now()}-${prev.length}`, text, mine: true },
      ]);
      setChatDraft("");
    } catch {
      setRoomStatus(t("call.callError"));
    }
  }, [channel, chatDraft, session, t]);

  if (!session || session.channelId !== channel) {
    return (
      <div className="flex min-h-full flex-col items-center justify-center gap-4 px-6 text-center">
        <p className="text-slate-200">{t("call.noSession")}</p>
        <button
          type="button"
          onClick={() => router.replace("/hub")}
          className="rounded-xl bg-white/10 px-4 py-2 text-sm font-medium text-white hover:bg-white/15"
        >
          {t("call.backHub")}
        </button>
      </div>
    );
  }

  if (!chatOnly && !appId) {
    return (
      <div className="flex min-h-full flex-col items-center justify-center px-6 text-center text-amber-200">
        {t("call.missingAgora")}
      </div>
    );
  }

  const remote = remoteUsers[0];

  if (chatOnly) {
    return (
      <div className="flex min-h-full flex-col bg-slate-950 text-white">
        <header className="border-b border-white/10 px-4 py-3">
          <p className="font-frank text-lg font-bold">{t("call.chatTitle")}</p>
          <p className="text-xs text-slate-400">
            {roomStatus || t("call.waitingLawyer")}
          </p>
        </header>
        <div className="flex-1 space-y-3 overflow-y-auto px-4 py-5">
          {chatMessages.length === 0 ? (
            <div className="flex h-full items-center justify-center text-center text-sm text-slate-400">
              {t("call.chatEmpty")}
            </div>
          ) : (
            chatMessages.map((message) => (
              <div
                key={message.id}
                className={`flex ${message.mine ? "justify-end" : "justify-start"}`}
              >
                <p
                  className={`max-w-[82%] whitespace-pre-wrap break-words rounded-2xl px-4 py-2 text-sm ${
                    message.mine
                      ? "bg-[#C5A059] text-black"
                      : "bg-white/10 text-white"
                  }`}
                >
                  {message.text}
                </p>
              </div>
            ))
          )}
        </div>
        <form
          className="border-t border-white/10 p-3"
          onSubmit={(e) => {
            e.preventDefault();
            sendCallChat();
          }}
        >
          <div className="mx-auto flex max-w-3xl gap-2">
            <input
              value={chatDraft}
              onChange={(e) => setChatDraft(e.target.value)}
              placeholder={t("call.chatPlaceholder")}
              className="min-w-0 flex-1 rounded-xl border border-white/10 bg-white/10 px-3 py-2 text-sm text-white outline-none placeholder:text-slate-500 focus:ring-2 focus:ring-[#C5A059]"
            />
            <button
              type="submit"
              disabled={!chatDraft.trim()}
              className="rounded-xl bg-[#C5A059] px-4 py-2 text-sm font-bold text-black disabled:opacity-50"
            >
              {t("chat.send")}
            </button>
            <button
              type="button"
              onClick={() => void leave()}
              className="rounded-xl bg-red-600 px-4 py-2 text-sm font-semibold text-white"
            >
              {t("call.end")}
            </button>
          </div>
        </form>
      </div>
    );
  }

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
            {isConnected ? t("call.waitingLawyer") : t("call.connecting")}
          </div>
        )}

        {videoSession && localCameraTrack && (
          <div className="absolute right-3 top-3 z-10 h-28 w-20 overflow-hidden rounded-lg border border-white/10 shadow-lg sm:h-36 sm:w-28">
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
            {micOn ? t("call.mute") : t("call.unmute")}
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
              {cameraOn ? t("call.cameraOff") : t("call.cameraOn")}
            </button>
          )}
          <button
            type="button"
            onClick={() => void leave()}
            className="rounded-full bg-red-600 px-5 py-2 text-sm font-semibold text-white hover:bg-red-500/100"
          >
            {t("call.end")}
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
