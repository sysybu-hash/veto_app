"use client";

import AgoraRTC, {
  type IAgoraRTCClient,
  type IAgoraRTCRemoteUser,
  type ILocalAudioTrack,
  type ILocalVideoTrack,
  type IRemoteAudioTrack,
  type IRemoteVideoTrack,
  type UID,
} from "agora-rtc-sdk-ng";
import {
  Camera,
  CameraOff,
  DoorOpen,
  Loader2,
  MessageCircle,
  Mic,
  MicOff,
  PhoneOff,
  RefreshCcw,
  Send,
  ShieldCheck,
  Video,
  Volume2,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { authFetch, apiUrl } from "@/api/apiClient";
import { getPublicAgoraAppId } from "@/lib/env";
import { connectSocket, getSocket } from "@/lib/socketClient";
import {
  useEmergencyStore,
  type SessionCallType,
  type SessionReadyState,
} from "@/store/useEmergencyStore";

type CallChatMessage = {
  id: string;
  text: string;
  mine: boolean;
};

type ResolvedSession = SessionReadyState & {
  peerName?: string | null;
  source: "socket" | "api";
};

type CallDetailsResponse = {
  success?: boolean;
  call?: {
    _id?: string;
    room_id?: string | null;
    call_type?: SessionCallType | null;
  };
};

type TokenResponse = {
  success?: boolean;
  channelId?: string;
  agoraToken?: string;
  agoraUid?: number;
  expiresAt?: number;
};

type RemoteTile = {
  uid: UID;
  hasAudio: boolean;
  hasVideo: boolean;
  audioTrack?: IRemoteAudioTrack;
  videoTrack?: IRemoteVideoTrack;
};

function isCallType(value: unknown): value is SessionCallType {
  return value === "audio" || value === "video" || value === "chat";
}

function newId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `m-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

function normalizeToken(value: string | null | undefined): string | null {
  const token = value?.trim() ?? "";
  return token.length > 0 ? token : null;
}

function normalizeUid(value: unknown): UID | null {
  const n = Number(value);
  if (Number.isFinite(n) && n > 0) return Math.trunc(n);
  return null;
}

function localLabel(callType: SessionCallType): string {
  if (callType === "chat") return "צ׳אט בלבד";
  if (callType === "audio") return "שיחת אודיו";
  return "שיחת וידאו";
}

function LocalVideoPreview({
  track,
  enabled,
}: {
  track: ILocalVideoTrack | null;
  enabled: boolean;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el || !track || !enabled) return;
    track.play(el, { fit: "cover", mirror: true });
    return () => {
      track.stop();
    };
  }, [enabled, track]);

  return (
    <div ref={ref} className="h-full w-full bg-slate-900">
      {(!track || !enabled) && (
        <div className="flex h-full w-full items-center justify-center text-xs font-bold text-slate-300">
          מצלמה כבויה
        </div>
      )}
    </div>
  );
}

function RemoteVideoStage({ tile }: { tile: RemoteTile | null }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el || !tile?.videoTrack) return;
    tile.videoTrack.play(el, { fit: "cover" });
    return () => {
      tile.videoTrack?.stop();
    };
  }, [tile?.uid, tile?.videoTrack]);

  useEffect(() => {
    tile?.audioTrack?.play();
  }, [tile?.audioTrack, tile?.uid]);

  return (
    <div ref={ref} className="relative h-full min-h-[420px] w-full overflow-hidden rounded-[2rem] bg-slate-950">
      {!tile?.hasVideo && (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-4 bg-slate-950 text-center text-white">
          <div className="grid h-24 w-24 place-items-center rounded-full border border-white/10 bg-white/10">
            {tile?.hasAudio ? (
              <Volume2 className="h-10 w-10 text-[#C5A059]" aria-hidden />
            ) : (
              <Video className="h-10 w-10 text-[#C5A059]" aria-hidden />
            )}
          </div>
          <div>
            <p className="font-frank text-2xl font-black">ממתינים לווידאו</p>
            <p className="mt-2 text-sm text-slate-400">
              {tile ? "האודיו פעיל. הווידאו יופיע כאן כשהצד השני יפעיל מצלמה." : "עוד לא זוהה משתתף נוסף בחדר."}
            </p>
          </div>
        </div>
      )}
    </div>
  );
}

export default function CallRoom({ channel }: { channel: string }) {
  const router = useRouter();
  const appId = getPublicAgoraAppId();
  const storeSession = useEmergencyStore((s) => s.sessionReady);
  const clearCallSession = useEmergencyStore((s) => s.clearCallSession);

  const micTrackRef = useRef<ILocalAudioTrack | null>(null);
  const cameraTrackRef = useRef<ILocalVideoTrack | null>(null);
  const joinedRef = useRef(false);
  const socketRoomRef = useRef<string | null>(null);

  const [session, setSession] = useState<ResolvedSession | null>(() => {
    if (storeSession?.channelId === channel) {
      return { ...storeSession, source: "socket" };
    }
    return null;
  });
  const [micOn, setMicOn] = useState(true);
  const [cameraOn, setCameraOn] = useState(true);
  const [connecting, setConnecting] = useState(
    !(storeSession?.channelId === channel && storeSession.callType === "chat"),
  );
  const [status, setStatus] = useState("מכינים את חדר השיחה...");
  const [error, setError] = useState<string | null>(null);
  const [remoteTiles, setRemoteTiles] = useState<RemoteTile[]>([]);
  const [localCameraTrack, setLocalCameraTrack] = useState<ILocalVideoTrack | null>(null);
  const [chatDraft, setChatDraft] = useState("");
  const [chatMessages, setChatMessages] = useState<CallChatMessage[]>([]);

  const [client] = useState<IAgoraRTCClient>(() => AgoraRTC.createClient({ mode: "rtc", codec: "vp8" }));

  const callType = session?.callType ?? storeSession?.callType ?? "video";
  const activeRemote = remoteTiles.find((u) => u.hasVideo) ?? remoteTiles[0] ?? null;
  const chatOnly = callType === "chat";
  const wantsVideo = callType === "video";

  const resolveSessionFromApi = useCallback(async () => {
    if (session || !channel) return;
    setConnecting(true);
    setStatus("משחזרים נתוני שיחה מהשרת...");
    setError(null);
    try {
      const [detailsRes, tokenRes] = await Promise.all([
        authFetch(apiUrl(`/api/calls/${encodeURIComponent(channel)}`), { method: "GET" }),
        authFetch(apiUrl(`/api/calls/${encodeURIComponent(channel)}/token`), { method: "POST" }),
      ]);

      const details = (await detailsRes.json().catch(() => ({}))) as CallDetailsResponse;
      const token = (await tokenRes.json().catch(() => ({}))) as TokenResponse;
      if (!detailsRes.ok) throw new Error("לא ניתן לטעון את פרטי השיחה.");
      if (!tokenRes.ok) throw new Error("לא ניתן לקבל Agora token.");

      const apiCallType = isCallType(details.call?.call_type) ? details.call.call_type : "video";
      const channelId = token.channelId || details.call?.room_id || channel;
      setSession({
        channelId,
        eventId: details.call?._id || channel,
        token: token.agoraToken || "",
        uid: Number(token.agoraUid || 0),
        callType: apiCallType,
        tokenExpiresAt: token.expiresAt,
        source: "api",
      });
      if (apiCallType === "chat") setConnecting(false);
    } catch (e) {
      setError(e instanceof Error ? e.message : "לא ניתן להתחיל את השיחה.");
      setConnecting(false);
    }
  }, [channel, session]);

  useEffect(() => {
    if (!session) void Promise.resolve().then(resolveSessionFromApi);
  }, [resolveSessionFromApi, session]);

  useEffect(() => {
    if (!session) return;
    const sock = connectSocket();
    const roomId = session.eventId || channel;
    socketRoomRef.current = roomId;

    const onChatReady = () => setStatus("שני הצדדים בחדר. אפשר להתחיל.");
    const onTimeout = () => setStatus("הצד השני לא הצטרף בזמן.");
    const onEnded = () => setStatus("השיחה הסתיימה בצד השני.");
    const onError = (raw: unknown) => {
      const msg =
        raw && typeof raw === "object" && "message" in raw && typeof (raw as { message?: unknown }).message === "string"
          ? (raw as { message: string }).message
          : "אירעה שגיאה בשיחה.";
      setStatus(msg);
    };
    const onChat = (raw: unknown) => {
      if (!raw || typeof raw !== "object") return;
      const text = (raw as { text?: unknown }).text;
      if (typeof text !== "string" || !text.trim()) return;
      setChatMessages((prev) => [...prev, { id: newId(), text: text.trim(), mine: false }]);
    };
    const onTokenRenewed = async (raw: unknown) => {
      if (!raw || typeof raw !== "object") return;
      const p = raw as { roomId?: string; agoraToken?: string };
      if (p.roomId !== channel && p.roomId !== session.channelId) return;
      const token = normalizeToken(p.agoraToken);
      if (!token) return;
      try {
        await client.renewToken(token);
      } catch (e) {
        console.warn("[call] renewToken failed:", e);
      }
    };

    sock.emit("join-call-room", { roomId, callType: session.callType });
    sock.on("chat-ready", onChatReady);
    sock.on("call-timeout", onTimeout);
    sock.on("call-ended", onEnded);
    sock.on("call-error", onError);
    sock.on("call-chat-message", onChat);
    sock.on("call-token-renewed", onTokenRenewed);

    return () => {
      sock.off("chat-ready", onChatReady);
      sock.off("call-timeout", onTimeout);
      sock.off("call-ended", onEnded);
      sock.off("call-error", onError);
      sock.off("call-chat-message", onChat);
      sock.off("call-token-renewed", onTokenRenewed);
      sock.emit("leave-call-room", { roomId });
      socketRoomRef.current = null;
    };
  }, [channel, client, session]);

  useEffect(() => {
    if (!session || chatOnly || !appId || joinedRef.current) return;

    let cancelled = false;

    const upsertRemote = (user: IAgoraRTCRemoteUser) => {
      setRemoteTiles((prev) => {
        const next: RemoteTile = {
          uid: user.uid,
          hasAudio: user.hasAudio,
          hasVideo: user.hasVideo,
          audioTrack: user.audioTrack,
          videoTrack: user.videoTrack,
        };
        const idx = prev.findIndex((x) => x.uid === user.uid);
        if (idx < 0) return [...prev, next];
        const copy = [...prev];
        copy[idx] = next;
        return copy;
      });
    };

    const join = async () => {
      setConnecting(true);
      setStatus("מתחברים ל-Agora...");
      setError(null);
      try {
        client.on("user-published", async (user, mediaType) => {
          await client.subscribe(user, mediaType);
          if (mediaType === "audio") user.audioTrack?.play();
          upsertRemote(user);
          setStatus("הצד השני מחובר.");
        });
        client.on("user-unpublished", (user) => {
          upsertRemote(user);
        });
        client.on("user-left", (user) => {
          setRemoteTiles((prev) => prev.filter((x) => x.uid !== user.uid));
          setStatus("הצד השני יצא מהשיחה.");
        });
        client.on("token-privilege-will-expire", () => {
          try {
            getSocket().emit("call-renew-token", { roomId: session.channelId });
          } catch {
            /* socket may be unavailable */
          }
        });

        const uid = normalizeUid(session.uid);
        await client.join(appId, session.channelId, normalizeToken(session.token), uid);
        joinedRef.current = true;
        if (cancelled) return;

        const tracks: Array<ILocalAudioTrack | ILocalVideoTrack> = [];
        if (callType === "audio" || callType === "video") {
          const mic = await AgoraRTC.createMicrophoneAudioTrack({
            encoderConfig: "speech_standard",
            AEC: true,
            ANS: true,
            AGC: true,
          });
          micTrackRef.current = mic;
          tracks.push(mic);
        }
        if (callType === "video") {
          try {
            const camera = await AgoraRTC.createCameraVideoTrack({
              encoderConfig: {
                width: 1280,
                height: 720,
                frameRate: 24,
                bitrateMin: 600,
                bitrateMax: 1800,
              },
              facingMode: "user",
            });
            cameraTrackRef.current = camera;
            setLocalCameraTrack(camera);
            tracks.push(camera);
          } catch (e) {
            setCameraOn(false);
            setStatus("המצלמה לא זמינה, ממשיכים עם אודיו.");
            console.warn("[call] camera track failed:", e);
          }
        }
        if (tracks.length > 0) await client.publish(tracks);
        setConnecting(false);
        setStatus("מחוברים. ממתינים לצד השני אם עדיין לא הצטרף.");
      } catch (e) {
        setConnecting(false);
        setError(e instanceof Error ? e.message : "החיבור ל-Agora נכשל.");
      }
    };

    void join();

    return () => {
      cancelled = true;
    };
  }, [appId, callType, chatOnly, client, session]);

  useEffect(() => {
    void micTrackRef.current?.setEnabled(micOn);
  }, [micOn]);

  useEffect(() => {
    void cameraTrackRef.current?.setEnabled(cameraOn);
  }, [cameraOn]);

  const leave = useCallback(async () => {
    const roomId = socketRoomRef.current || session?.eventId || channel;
    try {
      getSocket().emit("call-ended", { roomId });
    } catch {
      /* ignore */
    }
    try {
      micTrackRef.current?.close();
      cameraTrackRef.current?.close();
      micTrackRef.current = null;
      cameraTrackRef.current = null;
      setLocalCameraTrack(null);
    } catch {
      /* ignore */
    }
    try {
      if (joinedRef.current) await client.leave();
      joinedRef.current = false;
    } catch {
      /* ignore */
    }
    clearCallSession();
    router.replace("/hub");
  }, [channel, clearCallSession, client, router, session?.eventId]);

  const sendCallChat = useCallback(() => {
    const text = chatDraft.trim();
    if (!session || !text) return;
    const roomId = session.eventId || channel;
    try {
      getSocket().emit("call-chat-message", { roomId, text });
      setChatMessages((prev) => [...prev, { id: newId(), text, mine: true }]);
      setChatDraft("");
    } catch {
      setStatus("שליחת ההודעה נכשלה.");
    }
  }, [channel, chatDraft, session]);

  const retry = useCallback(async () => {
    if (joinedRef.current) {
      try {
        await client.leave();
      } catch {
        /* ignore */
      }
      joinedRef.current = false;
    }
    micTrackRef.current?.close();
    cameraTrackRef.current?.close();
    micTrackRef.current = null;
    cameraTrackRef.current = null;
    setLocalCameraTrack(null);
    setRemoteTiles([]);
    setSession(null);
    setError(null);
  }, [client]);

  if (!session && !error) {
    return (
      <div className="flex min-h-[calc(100dvh-5rem)] items-center justify-center bg-slate-950 px-6 text-white">
        <div className="text-center">
          <Loader2 className="mx-auto h-8 w-8 animate-spin text-[#C5A059]" aria-hidden />
          <p className="mt-4 font-black">טוען חדר שיחה...</p>
          <p className="mt-2 text-sm text-slate-400">משחזרים את פרטי Agora מהשרת.</p>
        </div>
      </div>
    );
  }

  const missingAgora = !chatOnly && !appId;

  return (
    <div className="min-h-[calc(100dvh-5rem)] bg-slate-950 px-3 py-4 text-white sm:px-5">
      <div className="mx-auto flex max-w-7xl flex-col gap-4">
        <header className="flex flex-col gap-3 rounded-3xl border border-white/10 bg-white/[0.06] px-4 py-4 shadow-2xl shadow-black/30 backdrop-blur md:flex-row md:items-center md:justify-between">
          <div>
            <p className="flex items-center gap-2 text-xs font-black uppercase tracking-widest text-[#C5A059]">
              <ShieldCheck className="h-4 w-4" aria-hidden />
              VETO SECURE CALL
            </p>
            <h1 className="mt-1 font-frank text-2xl font-black">שיחה בין אזרח לעורך דין</h1>
            <p className="mt-1 text-sm text-slate-300">
              {localLabel(callType)} · חדר {session?.channelId || channel}
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <span className={`rounded-full px-3 py-2 text-xs font-black ${error || missingAgora ? "bg-red-500/15 text-red-200" : "bg-emerald-500/15 text-emerald-200"}`}>
              {error || missingAgora ? "דורש טיפול" : connecting ? "מתחבר" : "פעיל"}
            </span>
            <button type="button" onClick={() => void retry()} className="inline-flex items-center gap-2 rounded-2xl border border-white/10 bg-white/10 px-3 py-2 text-sm font-bold hover:bg-white/15">
              <RefreshCcw className="h-4 w-4" aria-hidden />
              רענן חיבור
            </button>
            <button type="button" onClick={() => void leave()} className="inline-flex items-center gap-2 rounded-2xl bg-red-600 px-4 py-2 text-sm font-black text-white hover:bg-red-500">
              <PhoneOff className="h-4 w-4" aria-hidden />
              סיים שיחה
            </button>
          </div>
        </header>

        {(error || missingAgora) && (
          <div className="rounded-3xl border border-red-400/30 bg-red-950/45 px-4 py-3 text-sm text-red-100">
            {missingAgora
              ? "חסר NEXT_PUBLIC_AGORA_APP_ID בצד האתר. יש להגדיר אותו ב-Vercel בדיוק כמו AGORA_APP_ID של השרת ולבצע Redeploy."
              : error}
          </div>
        )}

        <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_360px]">
          <section className="relative min-h-[520px] overflow-hidden rounded-[2rem] border border-white/10 bg-black shadow-2xl shadow-black/40">
            {chatOnly ? (
              <div className="flex h-full min-h-[520px] flex-col items-center justify-center gap-4 text-center">
                <MessageCircle className="h-16 w-16 text-[#C5A059]" aria-hidden />
                <div>
                  <p className="font-frank text-3xl font-black">צ׳אט מאובטח</p>
                  <p className="mt-2 text-sm text-slate-400">השיחה הזו נבחרה כצ׳אט בלבד.</p>
                </div>
              </div>
            ) : (
              <>
                <RemoteVideoStage tile={activeRemote} />
                {wantsVideo && (
                  <div className="absolute end-4 top-4 h-36 w-52 overflow-hidden rounded-3xl border border-white/15 bg-slate-900 shadow-2xl">
                    <LocalVideoPreview track={localCameraTrack} enabled={cameraOn} />
                  </div>
                )}
                <div className="absolute bottom-4 start-4 rounded-2xl border border-white/10 bg-black/55 px-3 py-2 text-xs font-bold text-white backdrop-blur">
                  {connecting ? "מתחבר ל-Agora..." : status}
                </div>
              </>
            )}
          </section>

          <aside className="flex min-h-[520px] flex-col overflow-hidden rounded-[2rem] border border-white/10 bg-white/[0.06] backdrop-blur">
            <div className="border-b border-white/10 px-4 py-4">
              <p className="font-frank text-xl font-black">בקרת שיחה</p>
              <p className="mt-1 text-sm text-slate-400">{status}</p>
            </div>

            <div className="grid grid-cols-2 gap-2 p-4">
              {!chatOnly && (
                <>
                  <button
                    type="button"
                    onClick={() => setMicOn((v) => !v)}
                    className={`flex min-h-16 flex-col items-center justify-center gap-1 rounded-2xl border text-sm font-black ${
                      micOn ? "border-white/10 bg-white/10" : "border-amber-400/30 bg-amber-500/20 text-amber-100"
                    }`}
                  >
                    {micOn ? <Mic className="h-5 w-5" aria-hidden /> : <MicOff className="h-5 w-5" aria-hidden />}
                    {micOn ? "מיקרופון פעיל" : "מושתק"}
                  </button>
                  {wantsVideo && (
                    <button
                      type="button"
                      onClick={() => setCameraOn((v) => !v)}
                      className={`flex min-h-16 flex-col items-center justify-center gap-1 rounded-2xl border text-sm font-black ${
                        cameraOn ? "border-white/10 bg-white/10" : "border-amber-400/30 bg-amber-500/20 text-amber-100"
                      }`}
                    >
                      {cameraOn ? <Camera className="h-5 w-5" aria-hidden /> : <CameraOff className="h-5 w-5" aria-hidden />}
                      {cameraOn ? "מצלמה פעילה" : "מצלמה כבויה"}
                    </button>
                  )}
                </>
              )}
              <button
                type="button"
                onClick={() => router.push("/vault")}
                className="flex min-h-16 flex-col items-center justify-center gap-1 rounded-2xl border border-white/10 bg-white/10 text-sm font-black"
              >
                <ShieldCheck className="h-5 w-5" aria-hidden />
                כספת
              </button>
              <button
                type="button"
                onClick={() => void leave()}
                className="flex min-h-16 flex-col items-center justify-center gap-1 rounded-2xl border border-red-500/30 bg-red-600/25 text-sm font-black text-red-100"
              >
                <DoorOpen className="h-5 w-5" aria-hidden />
                יציאה
              </button>
            </div>

            <div className="min-h-0 flex-1 space-y-3 overflow-y-auto border-t border-white/10 px-4 py-4">
              {chatMessages.length === 0 ? (
                <div className="flex h-full items-center justify-center text-center text-sm text-slate-400">
                  אין הודעות בצ׳אט השיחה עדיין.
                </div>
              ) : (
                chatMessages.map((message) => (
                  <div key={message.id} className={`flex ${message.mine ? "justify-end" : "justify-start"}`}>
                    <p className={`max-w-[82%] whitespace-pre-wrap break-words rounded-2xl px-4 py-2 text-sm ${
                      message.mine ? "bg-[#C5A059] text-black" : "bg-white/10 text-white"
                    }`}>
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
              <div className="flex gap-2">
                <input
                  value={chatDraft}
                  onChange={(e) => setChatDraft(e.target.value)}
                  placeholder="כתבו הודעה במהלך השיחה..."
                  className="min-w-0 flex-1 rounded-2xl border border-white/10 bg-white/10 px-3 py-3 text-sm text-white outline-none placeholder:text-slate-500 focus:ring-2 focus:ring-[#C5A059]"
                />
                <button
                  type="submit"
                  disabled={!chatDraft.trim()}
                  className="grid h-12 w-12 place-items-center rounded-2xl bg-[#C5A059] text-black disabled:opacity-50"
                  aria-label="שליחת הודעה"
                >
                  <Send className="h-4 w-4" aria-hidden />
                </button>
              </div>
            </form>
          </aside>
        </div>
      </div>
    </div>
  );
}
