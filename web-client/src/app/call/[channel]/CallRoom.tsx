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
  Download,
  MessageCircle,
  Mic,
  MicOff,
  MonitorUp,
  PhoneOff,
  RefreshCcw,
  Save,
  Send,
  ShieldCheck,
  Trash2,
  Video,
  Volume2,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { syncSosArtifactsToVault } from "@/app/actions/vault";
import { authFetch, authMultipartFetch, apiUrl } from "@/api/apiClient";
import { getRoleFromJwt } from "@/lib/authToken";
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
  source: "socket" | "api" | "fallback";
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

type RecordingState = "idle" | "starting" | "recording" | "stopping" | "pending" | "ready" | "failed" | "unconfigured";

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

function postCallPathForRole(): string {
  const role = getRoleFromJwt();
  if (role === "lawyer") return "/dashboard";
  if (role === "admin") return "/admin/dashboard";
  return "/hub";
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
  const cleaningRef = useRef(false);
  const recordingStartedRef = useRef(false);
  const screenRecorderRef = useRef<MediaRecorder | null>(null);
  const screenStreamRef = useRef<MediaStream | null>(null);
  const screenChunksRef = useRef<Blob[]>([]);
  const finishCallRef = useRef<((options?: { notifyPeer?: boolean }) => Promise<void>) | null>(null);

  const [session, setSession] = useState<ResolvedSession | null>(() => {
    if (storeSession?.channelId === channel) {
      return { ...storeSession, source: "socket" };
    }
    return {
      channelId: channel,
      eventId: channel,
      token: "",
      uid: 0,
      callType: "video",
      source: "fallback",
    };
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
  const [recordingState, setRecordingState] = useState<RecordingState>("idle");
  const [screenRecording, setScreenRecording] = useState(false);
  const [endedForCitizen, setEndedForCitizen] = useState(false);
  const [artifactBusy, setArtifactBusy] = useState(false);
  const [artifactMessage, setArtifactMessage] = useState("");

  const [client] = useState<IAgoraRTCClient>(() => AgoraRTC.createClient({ mode: "rtc", codec: "vp8" }));

  const callType = session?.callType ?? storeSession?.callType ?? "video";
  const activeRemote = remoteTiles.find((u) => u.hasVideo) ?? remoteTiles[0] ?? null;
  const chatOnly = callType === "chat";
  const wantsVideo = callType === "video";

  const startCloudRecording = useCallback(async () => {
    if (!session || session.source === "fallback" || chatOnly || recordingStartedRef.current) return;
    recordingStartedRef.current = true;
    setRecordingState("starting");
    try {
      const res = await authFetch(apiUrl(`/api/calls/${encodeURIComponent(session.eventId)}/cloud-recording/start`), {
        method: "POST",
        body: JSON.stringify({ wantVideo: wantsVideo }),
      });
      if (res.status === 503) {
        setRecordingState("unconfigured");
        setStatus("השיחה פעילה. הקלטת ענן אינה מוגדרת בסביבה הזו.");
        return;
      }
      if (!res.ok) throw new Error("Cloud recording start failed");
      setRecordingState("recording");
    } catch (e) {
      console.warn("[call] cloud recording start failed:", e);
      setRecordingState("failed");
    }
  }, [chatOnly, session, wantsVideo]);

  const stopCloudRecording = useCallback(async () => {
    if (!session || session.source === "fallback" || !recordingStartedRef.current || recordingState === "unconfigured") return;
    setRecordingState("stopping");
    try {
      const res = await authFetch(apiUrl(`/api/calls/${encodeURIComponent(session.eventId)}/cloud-recording/stop`), {
        method: "POST",
      });
      if (res.status === 503) {
        setRecordingState("unconfigured");
        return;
      }
      if (!res.ok) throw new Error("Cloud recording stop failed");
      setRecordingState("pending");
    } catch (e) {
      console.warn("[call] cloud recording stop failed:", e);
      setRecordingState("failed");
    }
  }, [recordingState, session]);

  const uploadScreenRecording = useCallback(async (blob: Blob) => {
    if (!session || session.source === "fallback" || blob.size === 0) return;
    const file = new File([blob], `veto-screen-${session.eventId}.webm`, { type: blob.type || "video/webm" });
    const form = new FormData();
    form.append("recording", file);
    try {
      await authMultipartFetch(apiUrl(`/api/calls/${encodeURIComponent(session.eventId)}/screen-recording`), {
        method: "POST",
        body: form,
      });
    } catch (e) {
      console.warn("[call] screen recording upload failed:", e);
    }
  }, [session]);

  const stopScreenRecording = useCallback(() => {
    try {
      if (screenRecorderRef.current?.state === "recording") {
        screenRecorderRef.current.stop();
      }
    } catch {
      /* ignore */
    }
    screenStreamRef.current?.getTracks().forEach((track) => track.stop());
    screenStreamRef.current = null;
    setScreenRecording(false);
  }, []);

  const startScreenRecording = useCallback(async () => {
    if (!navigator.mediaDevices?.getDisplayMedia || screenRecording) return;
    try {
      const stream = await navigator.mediaDevices.getDisplayMedia({ video: true, audio: true });
      screenStreamRef.current = stream;
      screenChunksRef.current = [];
      const recorder = new MediaRecorder(stream, { mimeType: MediaRecorder.isTypeSupported("video/webm;codecs=vp9") ? "video/webm;codecs=vp9" : "video/webm" });
      screenRecorderRef.current = recorder;
      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) screenChunksRef.current.push(event.data);
      };
      recorder.onstop = () => {
        const blob = new Blob(screenChunksRef.current, { type: "video/webm" });
        screenChunksRef.current = [];
        void uploadScreenRecording(blob);
      };
      stream.getVideoTracks()[0]?.addEventListener("ended", stopScreenRecording, { once: true });
      recorder.start(1000);
      setScreenRecording(true);
    } catch {
      setStatus("הקלטת מסך לא הופעלה. הדפדפן דורש הרשאת שיתוף מסך.");
    }
  }, [screenRecording, stopScreenRecording, uploadScreenRecording]);

  const resolveSessionFromApi = useCallback(async () => {
    if (session?.source !== "fallback" || !channel) return;
    setConnecting(true);
    setStatus("משחזרים נתוני שיחה מהשרת. המסך מוכן, מחכים לפרטי החיבור...");
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
    if (session?.source === "fallback") void Promise.resolve().then(resolveSessionFromApi);
  }, [resolveSessionFromApi, session]);

  useEffect(() => {
    if (!session || session.source === "fallback") return;
    const sock = connectSocket();
    const roomId = session.eventId || channel;
    socketRoomRef.current = roomId;

    const onChatReady = () => setStatus("שני הצדדים בחדר. אפשר להתחיל.");
    const onTimeout = () => setStatus("הצד השני לא הצטרף בזמן.");
    const onEnded = () => {
      setStatus("השיחה הסתיימה בצד השני.");
      void finishCallRef.current?.({ notifyPeer: false });
    };
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
    if (!session || session.source === "fallback" || chatOnly || !appId || joinedRef.current) return;

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
        void startCloudRecording();
      } catch (e) {
        setConnecting(false);
        setError(e instanceof Error ? e.message : "החיבור ל-Agora נכשל.");
      }
    };

    void join();

    return () => {
      cancelled = true;
    };
  }, [appId, callType, chatOnly, client, session, startCloudRecording]);

  useEffect(() => {
    void micTrackRef.current?.setEnabled(micOn);
  }, [micOn]);

  useEffect(() => {
    void cameraTrackRef.current?.setEnabled(cameraOn);
  }, [cameraOn]);

  const cleanupMediaAndAgora = useCallback(async () => {
    if (cleaningRef.current) return;
    cleaningRef.current = true;
    stopScreenRecording();
    try {
      const localTracks = [micTrackRef.current, cameraTrackRef.current].filter(Boolean) as Array<ILocalAudioTrack | ILocalVideoTrack>;
      if (joinedRef.current && localTracks.length > 0) {
        await client.unpublish(localTracks).catch(() => undefined);
      }
      for (const track of localTracks) {
        try {
          track.stop();
          track.close();
        } catch {
          /* ignore */
        }
      }
      micTrackRef.current = null;
      cameraTrackRef.current = null;
      setLocalCameraTrack(null);
      setRemoteTiles([]);
      if (joinedRef.current) {
        await client.leave().catch(() => undefined);
      }
      joinedRef.current = false;
    } finally {
      cleaningRef.current = false;
    }
  }, [client, stopScreenRecording]);

  const finishCall = useCallback(async ({ notifyPeer = true }: { notifyPeer?: boolean } = {}) => {
    const roomId = socketRoomRef.current || session?.eventId || channel;
    if (notifyPeer) {
      try {
        getSocket().emit("call-ended", { roomId });
      } catch {
        /* ignore */
      }
    }
    await stopCloudRecording();
    await cleanupMediaAndAgora();
    clearCallSession();
    const role = getRoleFromJwt();
    if (role === "user") {
      setEndedForCitizen(true);
      setStatus("השיחה הסתיימה. אפשר לשמור את ההקלטה והתמלול לכספת או למחוק מהשרת.");
      return;
    }
    router.replace(postCallPathForRole());
  }, [channel, cleanupMediaAndAgora, clearCallSession, router, session?.eventId, stopCloudRecording]);

  useEffect(() => {
    finishCallRef.current = finishCall;
    return () => {
      finishCallRef.current = null;
    };
  }, [finishCall]);

  const leave = useCallback(async () => {
    await finishCall({ notifyPeer: true });
  }, [finishCall]);

  useEffect(() => {
    const onPageHide = () => {
      stopScreenRecording();
      micTrackRef.current?.stop();
      micTrackRef.current?.close();
      cameraTrackRef.current?.stop();
      cameraTrackRef.current?.close();
      micTrackRef.current = null;
      cameraTrackRef.current = null;
    };
    window.addEventListener("pagehide", onPageHide);
    window.addEventListener("beforeunload", onPageHide);
    return () => {
      window.removeEventListener("pagehide", onPageHide);
      window.removeEventListener("beforeunload", onPageHide);
      void cleanupMediaAndAgora();
    };
  }, [cleanupMediaAndAgora, stopScreenRecording]);

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
    await cleanupMediaAndAgora();
    setRemoteTiles([]);
    setSession(null);
    setError(null);
    recordingStartedRef.current = false;
    setRecordingState("idle");
  }, [cleanupMediaAndAgora]);

  const missingAgora = !chatOnly && !appId;
  const restoringSession = session?.source === "fallback";

  const saveArtifacts = useCallback(async () => {
    if (!session || session.source === "fallback") return;
    setArtifactBusy(true);
    setArtifactMessage("שומר את ההקלטה והתמלול לכספת...");
    try {
      const res = await authFetch(apiUrl(`/api/calls/${encodeURIComponent(session.eventId)}/artifacts/save`), {
        method: "POST",
      });
      if (!res.ok) throw new Error("שמירת ההקלטה נכשלה.");
      const sync = await syncSosArtifactsToVault();
      if (!sync.success) {
        setArtifactMessage("ההקלטה נשמרה בשרת. הסנכרון לכספת יושלם בהמשך.");
      } else {
        setArtifactMessage(sync.added > 0 ? "השיחה נשמרה בכספת." : "השיחה כבר קיימת בכספת או שהתמלול עדיין בעיבוד.");
      }
      setRecordingState("ready");
      setTimeout(() => router.replace("/vault"), 900);
    } catch (e) {
      setArtifactMessage(e instanceof Error ? e.message : "שמירת השיחה נכשלה.");
    } finally {
      setArtifactBusy(false);
    }
  }, [router, session]);

  const deleteArtifacts = useCallback(async () => {
    if (!session || session.source === "fallback") return;
    setArtifactBusy(true);
    setArtifactMessage("מוחק את ההקלטה והתמלול מהשרת...");
    try {
      const res = await authFetch(apiUrl(`/api/calls/${encodeURIComponent(session.eventId)}/artifacts`), {
        method: "DELETE",
      });
      if (!res.ok) throw new Error("מחיקת ההקלטה נכשלה.");
      setArtifactMessage("ההקלטה והתמלול נמחקו.");
      setTimeout(() => router.replace("/hub"), 700);
    } catch (e) {
      setArtifactMessage(e instanceof Error ? e.message : "מחיקת השיחה נכשלה.");
    } finally {
      setArtifactBusy(false);
    }
  }, [router, session]);

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
            {!chatOnly ? (
              <span className={`inline-flex items-center gap-2 rounded-full px-3 py-2 text-xs font-black ${
                recordingState === "recording" || recordingState === "pending" || recordingState === "stopping"
                  ? "bg-red-500/15 text-red-100"
                  : recordingState === "unconfigured"
                    ? "bg-amber-500/15 text-amber-100"
                    : "bg-white/10 text-slate-200"
              }`}>
                <span className={`h-2.5 w-2.5 rounded-full ${recordingState === "recording" ? "animate-pulse bg-red-500" : "bg-slate-400"}`} />
                {recordingState === "recording"
                  ? "מוקלט"
                  : recordingState === "pending" || recordingState === "stopping"
                    ? "תמלול בעיבוד"
                    : recordingState === "unconfigured"
                      ? "הקלטה לא מוגדרת"
                      : "מכין הקלטה"}
              </span>
            ) : null}
            <span className={`rounded-full px-3 py-2 text-xs font-black ${error || missingAgora ? "bg-red-500/15 text-red-200" : "bg-emerald-500/15 text-emerald-200"}`}>
              {error || missingAgora ? "דורש טיפול" : restoringSession ? "משחזר" : connecting ? "מתחבר" : "פעיל"}
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

        {(error || missingAgora || restoringSession) && (
          <div className="rounded-3xl border border-red-400/30 bg-red-950/45 px-4 py-3 text-sm text-red-100">
            {restoringSession
              ? "טוען את פרטי השיחה מהשרת. הבקרות נשארות זמינות כדי שהמסך לא יישאר ריק."
              : missingAgora
                ? "חסר NEXT_PUBLIC_AGORA_APP_ID בצד האתר. יש להגדיר אותו ב-Vercel בדיוק כמו AGORA_APP_ID של השרת ולבצע Redeploy."
                : error}
          </div>
        )}

        <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_360px]">
          <section className="relative min-h-[520px] overflow-hidden rounded-[2rem] border border-white/10 bg-black shadow-2xl shadow-black/40">
            {!chatOnly ? (
              <div className="pointer-events-none absolute start-5 top-5 z-20 flex items-center gap-3 rounded-2xl border border-white/10 bg-black/45 px-3 py-2 text-white backdrop-blur">
                <span className="font-frank text-lg font-black">VETO</span>
                <span className="inline-flex items-center gap-1 rounded-full bg-red-600/90 px-2 py-1 text-[11px] font-black">
                  <span className="h-2 w-2 animate-pulse rounded-full bg-white" />
                  מוקלט
                </span>
              </div>
            ) : null}
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
                  {restoringSession ? "משחזר פרטי חדר..." : connecting ? "מתחבר ל-Agora..." : status}
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
              {!chatOnly && (
                <button
                  type="button"
                  onClick={() => screenRecording ? stopScreenRecording() : void startScreenRecording()}
                  className={`flex min-h-16 flex-col items-center justify-center gap-1 rounded-2xl border text-sm font-black ${
                    screenRecording ? "border-red-400/30 bg-red-500/20 text-red-100" : "border-white/10 bg-white/10"
                  }`}
                >
                  {screenRecording ? <Download className="h-5 w-5" aria-hidden /> : <MonitorUp className="h-5 w-5" aria-hidden />}
                  {screenRecording ? "עצור מסך" : "הקלט מסך"}
                </button>
              )}
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
      {endedForCitizen ? (
        <div className="fixed inset-0 z-[80] grid place-items-center bg-slate-950/75 px-4 backdrop-blur" dir="rtl">
          <div className="w-full max-w-lg rounded-[2rem] border border-white/15 bg-slate-900 p-6 text-white shadow-2xl">
            <p className="font-frank text-3xl font-black">השיחה הסתיימה</p>
            <p className="mt-3 text-sm leading-6 text-slate-300">
              ההקלטה והתמלול בעיבוד. אפשר לשמור את השיחה בכספת, או למחוק את ההקלטה והתמלול מהשרת.
            </p>
            {artifactMessage ? (
              <div className="mt-4 rounded-2xl border border-white/10 bg-white/10 p-3 text-sm font-bold text-slate-100">
                {artifactMessage}
              </div>
            ) : null}
            <div className="mt-6 grid gap-3 sm:grid-cols-2">
              <button
                type="button"
                disabled={artifactBusy}
                onClick={() => void saveArtifacts()}
                className="inline-flex items-center justify-center gap-2 rounded-2xl bg-[#C5A059] px-4 py-3 text-sm font-black text-black disabled:opacity-60"
              >
                <Save className="h-5 w-5" aria-hidden />
                שמור לכספת
              </button>
              <button
                type="button"
                disabled={artifactBusy}
                onClick={() => void deleteArtifacts()}
                className="inline-flex items-center justify-center gap-2 rounded-2xl border border-red-400/40 bg-red-600/20 px-4 py-3 text-sm font-black text-red-100 disabled:opacity-60"
              >
                <Trash2 className="h-5 w-5" aria-hidden />
                מחק מהשרת
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
