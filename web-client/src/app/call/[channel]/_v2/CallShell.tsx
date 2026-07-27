"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type {
  ILocalAudioTrack,
  ILocalVideoTrack,
  IMicrophoneAudioTrack,
  ICameraVideoTrack,
} from "agora-rtc-sdk-ng";
import { apiUrl, authFetch } from "@/api/apiClient";
import { createActionPlan, type ActionPlan } from "@/api/advancedApi";
import { PRICING } from "@/api/paymentApi";
import { getUserIdFromJwt, getRoleFromJwt } from "@/lib/authToken";
import { connectSocket, getSocket } from "@/lib/socketClient";
import { useEmergencyStore, type PreCallReadiness } from "@/store/useEmergencyStore";
import { getPublicAgoraAppId } from "@/lib/env";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { useTrWithFallback } from "./lib/trWithFallback";

import { useAgoraClient } from "./hooks/useAgoraClient";
import { useAgoraDevices } from "./hooks/useAgoraDevices";
import { useCallTimer } from "./hooks/useCallTimer";
import { useCloudRecording } from "./hooks/useCloudRecording";
import { useRealtimeTranscription } from "./hooks/useRealtimeTranscription";
import { useCaptionsTranslation } from "./hooks/useCaptionsTranslation";
import { useCallChat } from "./hooks/useCallChat";
import { useScreenShare } from "./hooks/useScreenShare";
import { useKeyboardShortcuts } from "./hooks/useKeyboardShortcuts";
import { useSaveToVault } from "./hooks/useSaveToVault";
import { summariseQuality } from "./hooks/useNetworkQuality";

import { PreCallCheck } from "./components/PreCallCheck";
import { ConsentBanner } from "./components/ConsentBanner";
import { CallStage } from "./components/CallStage";
import { ControlBar } from "./components/ControlBar";
import { SidePanel } from "./components/SidePanel";
import { CaptionsOverlay } from "./components/CaptionsOverlay";
import { ConnectionMeter } from "./components/ConnectionMeter";
import { ReconnectingOverlay } from "./components/ReconnectingOverlay";
import { EndCallSummary, type SummaryShape } from "./components/EndCallSummary";
import { DocumentPipToggle } from "./components/DocumentPip";

import { VIDEO_ENCODER_PROFILE } from "./lib/codec";
import { deriveE2EEMaterial, isE2EESupported } from "./lib/e2eeConfig";

type SharedFile = {
  cloud_url: string;
  mime: string | null;
  by_role: "user" | "lawyer";
  ts: string;
  original_name: string | null;
};

const ENABLE_E2EE = process.env.NEXT_PUBLIC_ENABLE_E2EE === "true";

/**
 * Main v2 call surface — replaces the agora-rtc-react CallRoom for users
 * with the `NEXT_PUBLIC_CALL_V2` flag enabled. Keeps the same socket
 * contract (`join-call-room`, `call-ended`, `call-token-renewed`) so the
 * backend doesn't have to change.
 */
export function CallShell({ channel }: { channel: string }) {
  const router = useRouter();
  const t = useTrWithFallback();
  const { locale } = useTranslation();

  const session = useEmergencyStore((s) => s.sessionReady);
  const clearCallSession = useEmergencyStore((s) => s.clearCallSession);
  const hasActiveSession = session?.channelId === channel;
  const callType = session?.callType ?? "video";
  const isVideo = callType === "video";
  const isChatOnly = callType === "chat";

  const myUserId = useMemo(() => getUserIdFromJwt() ?? "", []);
  const myRole: "user" | "lawyer" = useMemo(
    () => (getRoleFromJwt() === "lawyer" ? "lawyer" : "user"),
    [],
  );

  // Permission grant fired from the call-type (citizen) / accept-case (lawyer)
  // button on a *different* route (hub/dashboard) — read via the shared store
  // instead of PreCallCheck, so the happy path skips a whole extra screen.
  const storePreCallReadiness = useEmergencyStore((s) => s.preCallReadiness);
  const preCallPermissionStatus = useEmergencyStore(
    (s) => s.preCallPermissionStatus,
  );

  // Pre-call lobby state.
  const [preCallReady, setPreCallReady] = useState<PreCallReadiness | null>(
    isChatOnly
      ? { micId: null, cameraId: null, speakerId: null, ready: true }
      : storePreCallReadiness,
  );

  // The getUserMedia() promise kicked off on hub/dashboard may still be
  // in flight when this route mounts (fast session_ready) — pick up the
  // store update once it resolves.
  useEffect(() => {
    if (preCallReady || isChatOnly || !storePreCallReadiness) return;
    queueMicrotask(() => {
      setPreCallReady(storePreCallReadiness);
    });
  }, [storePreCallReadiness, preCallReady, isChatOnly]);

  // Agora.
  const { client, AgoraRTC, remoteUsers, connectionState, networkQuality, ready } =
    useAgoraClient();
  const networkSummary = useMemo(
    () => summariseQuality(networkQuality),
    [networkQuality],
  );

  const { selectedSpeakerId } = useAgoraDevices();

  // Local tracks.
  const [micTrack, setMicTrack] = useState<IMicrophoneAudioTrack | null>(null);
  const [cameraTrack, setCameraTrack] = useState<ICameraVideoTrack | null>(null);
  const [micOn, setMicOn] = useState(true);
  const [cameraOn, setCameraOn] = useState(true);
  const [denoiserOn, setDenoiserOn] = useState(false);
  const [bgBlurOn, setBgBlurOn] = useState(false);
  const denoiserProcessorRef = useRef<unknown | null>(null);
  const bgProcessorRef = useRef<unknown | null>(null);

  // Joined / publishing state.
  const [joined, setJoined] = useState(false);
  const [joinError, setJoinError] = useState<string | null>(null);

  // Recording / transcription / chat / files.
  const eventId = session?.eventId ?? null;
  const recording = useCloudRecording(eventId, { wantVideo: isVideo });
  const rtt = useRealtimeTranscription(eventId, client);
  const chat = useCallChat({
    eventId,
    myUserId,
    myRole,
  });
  const [captionsOn, setCaptionsOn] = useState(false);
  const [translateCaptions, setTranslateCaptions] = useState(false);
  const captionTranslations = useCaptionsTranslation({
    segments: rtt.segments,
    enabled: captionsOn && translateCaptions,
    targetLang: locale,
  });

  const screen = useScreenShare({
    client,
    AgoraRTC,
    cameraTrack,
  });

  const [sharedFiles, setSharedFiles] = useState<SharedFile[]>([]);
  const refreshFiles = useCallback(async () => {
    if (!eventId) return;
    try {
      const res = await authFetch(apiUrl(`/api/calls/${eventId}`));
      if (!res.ok) return;
      const data = (await res.json()) as { call?: { shared_files?: SharedFile[] } };
      setSharedFiles(data.call?.shared_files ?? []);
    } catch {
      /* ignore */
    }
  }, [eventId]);

  // Side panel + summary.
  const [sideOpen, setSideOpen] = useState(false);
  const [summary, setSummary] = useState<SummaryShape | null>(null);
  const [actionPlan, setActionPlan] = useState<ActionPlan | null>(null);
  const vault = useSaveToVault(eventId);

  // Chat unread badge for the redesigned ControlBar — useCallChat itself has
  // no unread concept, so track "how many messages had the panel already
  // seen" locally and mark everything seen whenever it's opened.
  const [lastSeenChatCount, setLastSeenChatCount] = useState(0);
  useEffect(() => {
    if (!sideOpen) return;
    queueMicrotask(() => {
      setLastSeenChatCount(chat.messages.length);
    });
  }, [sideOpen, chat.messages.length]);
  const chatUnread = !sideOpen && chat.messages.length > lastSeenChatCount;

  useEffect(() => {
    if (vault.status !== "saved") return;
    router.refresh();
  }, [vault.status, router]);

  // Timer.
  const [callStartedAt] = useState<number>(() => Date.now());
  const { elapsedSec, label: timerLabel } = useCallTimer(callStartedAt);
  const freeSec = PRICING.freeCallMinutes * 60;
  const overSec = Math.max(0, elapsedSec - freeSec);
  const overtimePreviewIls =
    Math.ceil(overSec / 60) * PRICING.overtimeIlsPerMin;

  // Remote video element ref for PiP.
  const [remoteVideoEl, setRemoteVideoEl] = useState<HTMLVideoElement | null>(
    null,
  );

  // ── Effect: create local tracks once Agora SDK + lobby are ready ──
  useEffect(() => {
    if (!AgoraRTC || !preCallReady || isChatOnly) return;
    let cancelled = false;
    let mic: IMicrophoneAudioTrack | null = null;
    let cam: ICameraVideoTrack | null = null;

    void (async () => {
      try {
        mic = await AgoraRTC.createMicrophoneAudioTrack({
          microphoneId: preCallReady.micId ?? undefined,
          AEC: true,
          ANS: true,
          AGC: true,
        });
        if (cancelled) {
          mic.close();
          return;
        }
        if (isVideo) {
          cam = await AgoraRTC.createCameraVideoTrack({
            cameraId: preCallReady.cameraId ?? undefined,
            encoderConfig: VIDEO_ENCODER_PROFILE,
          });
          if (cancelled) {
            cam.close();
            return;
          }
        }
        setMicTrack(mic);
        setCameraTrack(cam);
      } catch (err) {
        setJoinError(err instanceof Error ? err.message : String(err));
      }
    })();

    return () => {
      cancelled = true;
      try {
        mic?.close();
      } catch {
        /* ignore */
      }
      try {
        cam?.close();
      } catch {
        /* ignore */
      }
    };
  }, [AgoraRTC, isVideo, isChatOnly, preCallReady]);

  // ── Effect: switch speaker output (Chrome-only). ──
  useEffect(() => {
    if (!selectedSpeakerId) return;
    remoteUsers.forEach((u) => {
      const audio = u.audioTrack as
        | (ILocalAudioTrack & { setPlaybackDevice?: (id: string) => Promise<void> })
        | undefined;
      audio?.setPlaybackDevice?.(selectedSpeakerId).catch(() => {});
    });
  }, [selectedSpeakerId, remoteUsers]);

  // ── Effect: toggle local enabled flags. ──
  useEffect(() => {
    micTrack?.setEnabled(micOn);
  }, [micTrack, micOn]);
  useEffect(() => {
    cameraTrack?.setEnabled(cameraOn);
  }, [cameraTrack, cameraOn]);

  // ── Effect: join the channel + publish. ──
  useEffect(() => {
    if (!ready || !client || !AgoraRTC) return;
    if (!hasActiveSession || !session || !preCallReady) return;
    if (isChatOnly) return;
    const appId = getPublicAgoraAppId();
    if (!appId) {
      queueMicrotask(() => setJoinError("Missing Agora App ID"));
      return;
    }
    if (!micTrack) return; // wait for tracks
    if (isVideo && !cameraTrack) return;

    let cancelled = false;
    void (async () => {
      try {
        if (ENABLE_E2EE && isE2EESupported()) {
          const secret = session.e2eeSecret?.trim();
          if (!secret) {
            console.error(
              "[call/v2] E2EE is enabled (NEXT_PUBLIC_ENABLE_E2EE) but session.e2eeSecret is missing. Refusing to derive keys — check session_ready / GET /api/calls/:id.",
            );
          } else {
            try {
              const { key, salt } = await deriveE2EEMaterial(
                session.eventId,
                secret,
              );
              const enc = client as unknown as {
                setEncryptionConfig?: (
                  mode: string,
                  salt: Uint8Array,
                  key: Uint8Array,
                ) => void;
              };
              enc.setEncryptionConfig?.("aes-256-gcm2", salt, key);
            } catch (err) {
              console.warn("[call/v2] e2ee setup failed:", err);
            }
          }
        }

        await client.join(appId, session.channelId, session.token, session.uid);
        if (cancelled) return;
        const tracks: (IMicrophoneAudioTrack | ICameraVideoTrack)[] = [micTrack];
        if (isVideo && cameraTrack) tracks.push(cameraTrack);
        await client.publish(tracks);
        if (cancelled) return;
        setJoined(true);
      } catch (err) {
        setJoinError(err instanceof Error ? err.message : String(err));
      }
    })();

    return () => {
      cancelled = true;
      void (async () => {
        try {
          if (client.connectionState !== "DISCONNECTED") await client.leave();
        } catch {
          /* ignore */
        }
      })();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    ready,
    client,
    AgoraRTC,
    micTrack,
    cameraTrack,
    isVideo,
    isChatOnly,
    hasActiveSession,
    session?.eventId,
  ]);

  // ── Effect: socket room (chat + token renewal). ──
  useEffect(() => {
    if (!session || session.channelId !== channel) return;
    let sock;
    try {
      sock = connectSocket();
    } catch {
      return undefined;
    }
    const roomId = session.eventId || channel;
    sock.emit("join-call-room", { roomId, callType: session.callType });

    const onTimeout = () => setJoinError(t("call.peerTimeout", "Peer timed out"));
    const onError = (raw: unknown) => {
      const msg =
        raw && typeof raw === "object" && "message" in raw &&
        typeof (raw as { message?: unknown }).message === "string"
          ? (raw as { message: string }).message
          : t("call.callError", "Call error");
      setJoinError(msg);
    };
    sock.on("call-timeout", onTimeout);
    sock.on("call-error", onError);

    const onTokenRenew = async (raw: unknown) => {
      if (!client) return;
      const p = raw as { roomId?: string; agoraToken?: string };
      if (p.roomId !== channel || !p.agoraToken) return;
      try {
        await client.renewToken(p.agoraToken);
      } catch {
        /* ignore */
      }
    };
    sock.on("call-token-renewed", onTokenRenew);

    return () => {
      sock.emit("leave-call-room", { roomId });
      sock.off("call-timeout", onTimeout);
      sock.off("call-error", onError);
      sock.off("call-token-renewed", onTokenRenew);
    };
  }, [channel, client, session, t]);

  // ── Effect: token-privilege-will-expire → ask backend for a new token. ──
  useEffect(() => {
    if (!client) return;
    const onExpire = () => {
      try {
        getSocket().emit("call-renew-token", { roomId: channel });
      } catch {
        /* ignore */
      }
    };
    client.on("token-privilege-will-expire", onExpire);
    return () => client.off("token-privilege-will-expire", onExpire);
  }, [client, channel]);

  // ── Effect: hydrate shared files once. ──
  useEffect(() => {
    queueMicrotask(() => {
      void refreshFiles();
    });
  }, [refreshFiles]);

  // ── Toggle handlers ──
  const toggleDenoiser = useCallback(async () => {
    if (!micTrack) return;
    try {
      const ext = await import("./lib/agoraExtensions");
      const sdk = AgoraRTC;
      if (!sdk) return;
      const { denoiser } = await ext.registerAgoraExtensions(sdk);
      if (!denoiser) return;
      if (!denoiserProcessorRef.current) {
        const proc = denoiser.createProcessor();
        denoiserProcessorRef.current = proc;
        await (
          micTrack as unknown as {
            pipe: (p: unknown) => { pipe: (dst: unknown) => unknown };
            processorDestination: unknown;
          }
        )
          .pipe(proc)
          .pipe(
            (
              micTrack as unknown as { processorDestination: unknown }
            ).processorDestination,
          );
      }
      const proc = denoiserProcessorRef.current as {
        enabled?: boolean;
        enable: () => Promise<void>;
        disable: () => Promise<void>;
      };
      if (proc.enabled) {
        await proc.disable();
        setDenoiserOn(false);
      } else {
        await proc.enable();
        setDenoiserOn(true);
      }
    } catch (err) {
      console.warn("[call/v2] denoiser toggle failed:", err);
    }
  }, [micTrack, AgoraRTC]);

  const toggleBgBlur = useCallback(async () => {
    if (!cameraTrack || !AgoraRTC) return;
    try {
      const ext = await import("./lib/agoraExtensions");
      const { virtualBg } = await ext.registerAgoraExtensions(AgoraRTC);
      if (!virtualBg) return;
      if (!bgProcessorRef.current) {
        const proc = virtualBg.createProcessor();
        bgProcessorRef.current = proc;
        await proc.init();
        const trackPipe = cameraTrack as unknown as {
          pipe: (p: unknown) => { pipe: (dst: unknown) => unknown };
          processorDestination: unknown;
        };
        trackPipe.pipe(proc).pipe(trackPipe.processorDestination);
        proc.setOptions({ type: "blur", blurDegree: 2 });
      }
      const proc = bgProcessorRef.current as {
        enabled?: boolean;
        enable: () => Promise<void>;
        disable: () => Promise<void>;
      };
      if (proc.enabled) {
        await proc.disable();
        setBgBlurOn(false);
      } else {
        await proc.enable();
        setBgBlurOn(true);
      }
    } catch (err) {
      console.warn("[call/v2] bg blur toggle failed:", err);
    }
  }, [cameraTrack, AgoraRTC]);

  const toggleScreenShare = useCallback(async () => {
    if (screen.isSharing) await screen.stop();
    else await screen.start();
  }, [screen]);

  const toggleRecording = useCallback(async () => {
    if (myRole !== "user") return;
    if (recording.status === "recording") await recording.stop();
    else await recording.start();
  }, [myRole, recording]);

  const toggleCaptions = useCallback(async () => {
    if (captionsOn) {
      setCaptionsOn(false);
      await rtt.stop();
    } else {
      await rtt.start();
      setCaptionsOn(true);
    }
  }, [captionsOn, rtt]);

  // ── End-call flow ──
  const finalize = useCallback(async () => {
    try {
      cameraTrack?.close();
      micTrack?.close();
      screen.screenTrack?.close();
    } catch {
      /* ignore */
    }
    try {
      if (client && client.connectionState !== "DISCONNECTED") {
        await client.leave();
      }
    } catch {
      /* ignore */
    }
    try {
      getSocket().emit("call-ended", { roomId: session?.eventId || channel });
    } catch {
      /* ignore */
    }
  }, [cameraTrack, micTrack, screen.screenTrack, client, channel, session]);

  const finishBilling = useCallback(async (): Promise<SummaryShape> => {
    const minutes = Math.max(
      1,
      Math.ceil((Date.now() - callStartedAt) / 60_000),
    );
    const overtimeMin = Math.max(0, minutes - PRICING.freeCallMinutes);
    const fallback: SummaryShape = {
      minutes,
      base: PRICING.consultationIls,
      overtime: overtimeMin * PRICING.overtimeIlsPerMin,
      total:
        PRICING.consultationIls + overtimeMin * PRICING.overtimeIlsPerMin,
    };
    if (!eventId) return fallback;
    try {
      const res = await authFetch(
        apiUrl(`/api/calls/${eventId}/finish-billing`),
        {
          method: "POST",
          body: JSON.stringify({
            durationSeconds: Math.max(1, Math.floor((Date.now() - callStartedAt) / 1000)),
          }),
        },
      );
      if (!res.ok) return fallback;
      const data = (await res.json()) as {
        charge?: {
          minutes?: number;
          baseIls?: number;
          overtimeIls?: number;
          totalIls?: number;
          status?: string;
        };
      };
      if (!data.charge) return fallback;
      return {
        minutes: data.charge.minutes ?? fallback.minutes,
        base: data.charge.baseIls ?? fallback.base,
        overtime: data.charge.overtimeIls ?? fallback.overtime,
        total: data.charge.totalIls ?? fallback.total,
        status: data.charge.status,
      };
    } catch {
      return fallback;
    }
  }, [callStartedAt, eventId]);

  const postCallHome = myRole === "lawyer" ? "/dashboard" : "/hub";

  const endCall = useCallback(async () => {
    if (isChatOnly) {
      await finalize();
      clearCallSession();
      router.replace(postCallHome);
      return;
    }
    // Cloud recording stop is citizen-only on the API; avoid 403 for lawyers.
    if (
      myRole === "user" &&
      (recording.status === "recording" ||
        recording.status === "starting" ||
        recording.status === "stopping")
    ) {
      try {
        await recording.stop();
      } catch {
        /* ignore */
      }
    }
    if (rtt.status === "running") {
      try {
        await rtt.stop();
      } catch {
        /* ignore */
      }
    }
    const next = await finishBilling();
    setSummary(next);
    if (eventId) {
      void createActionPlan(eventId).then(setActionPlan).catch(() => setActionPlan(null));
    }
    await finalize();
  }, [
    isChatOnly,
    finalize,
    clearCallSession,
    router,
    recording,
    rtt,
    finishBilling,
    eventId,
    myRole,
    postCallHome,
  ]);

  const closeSummary = useCallback(() => {
    clearCallSession();
    router.replace(postCallHome);
  }, [clearCallSession, router, postCallHome]);

  // Keyboard shortcuts.
  useKeyboardShortcuts({
    toggleMic: () => setMicOn((v) => !v),
    toggleCamera: () => isVideo && setCameraOn((v) => !v),
    toggleChat: () => setSideOpen((v) => !v),
    endCall: () => void endCall(),
    pushToTalkDown: () => micTrack?.setEnabled(true),
    pushToTalkUp: () => micTrack?.setEnabled(micOn),
  });

  // ── Renders ──
  if (!hasActiveSession) {
    return (
      <div className="veto-call-keep-dark fixed inset-0 z-[70] flex h-[100dvh] w-screen flex-col items-center justify-center gap-3 bg-black px-6 text-center text-slate-200">
        <p className="font-bold">{t("call.noSession", "No active session")}</p>
        <button
          type="button"
          onClick={() => router.replace(postCallHome)}
          className="rounded-xl bg-[#C5A059] px-4 py-2 text-sm font-bold text-black"
        >
          {t("call.backHub", "Back to hub")}
        </button>
      </div>
    );
  }

  if (!preCallReady) {
    // Happy path: permission was already requested from the call-type
    // (citizen) / accept-case (lawyer) button on the previous screen — this
    // is a brief, non-interactive wait for that promise to resolve, not a
    // second screen the user has to act on.
    if (preCallPermissionStatus === "pending") {
      return (
        <div className="veto-call-keep-dark fixed inset-0 z-[70] flex h-[100dvh] w-screen flex-col items-center justify-center gap-3 bg-black px-6 text-center text-slate-200">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[#C5A059]/30 border-t-[#C5A059]" />
          <p className="text-sm text-slate-400">
            {t("call.v2.preparing", "Setting up your camera & mic…")}
          </p>
        </div>
      );
    }
    // "denied" (permission was refused) or "idle" (this route was reached
    // without going through the new buttons — defensive fallback) both fall
    // back to the full manual picker, unchanged.
    return (
      <div className="veto-call-keep-dark fixed inset-0 z-[70] h-[100dvh] w-screen bg-black">
        <PreCallCheck
          mode={callType}
          onReady={(r) => {
            useEmergencyStore.getState().setPreCallReadiness(r);
            setPreCallReady(r);
          }}
        />
      </div>
    );
  }

  return (
    <div className="@container/shell veto-call-keep-dark fixed inset-0 z-[70] flex h-[100dvh] w-screen flex-col overflow-hidden bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white">
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.12]"
        style={{
          backgroundImage:
            "radial-gradient(ellipse 80% 50% at 50% -20%, rgba(197,160,89,0.45), transparent 55%)",
        }}
        aria-hidden
      />

      {/* Top header strip */}
      <div className="absolute inset-x-0 top-0 z-20 flex items-start justify-between gap-2 px-3 pt-3">
        <div className="flex items-center gap-2 rounded-2xl border border-[#C5A059]/25 bg-black/55 px-3 py-1.5 text-xs text-slate-100 shadow-lg backdrop-blur-md">
          <span className="font-mono tabular-nums tracking-tight text-[#C5A059]">
            {timerLabel}
          </span>
          {overSec > 0 && (
            <span className="border-s border-white/15 ps-2 text-amber-200/95">
              +₪{overtimePreviewIls.toFixed(2)}
            </span>
          )}
        </div>
        <ConnectionMeter quality={networkSummary} />
      </div>

      {/* Main video stage */}
      <div className="relative flex-1 overflow-hidden px-2 pb-2 pt-14 @md:px-4 @md:pb-3 @md:pt-16">
        <div className="relative h-full min-h-0 overflow-hidden rounded-3xl border border-white/[0.08] bg-zinc-950/80 shadow-[0_0_0_1px_rgba(197,160,89,0.06),0_24px_80px_rgba(0,0,0,0.65)] ring-1 ring-[#C5A059]/10">
        <CallStage
          localCameraTrack={cameraTrack as ILocalVideoTrack | null}
          remoteUsers={remoteUsers}
          videoEnabled={isVideo}
          cameraOn={cameraOn}
          isScreenSharing={screen.isSharing}
          setRemoteVideoEl={setRemoteVideoEl}
        />

        <ConsentBanner
          consent={recording.consent}
          onChoose={(g) => void recording.recordOwnConsent(g)}
          myRole={myRole}
          recordingStatus={recording.status}
        />

        <CaptionsOverlay
          enabled={captionsOn}
          segments={rtt.segments}
          translations={translateCaptions ? captionTranslations : undefined}
        />

        <ReconnectingOverlay state={connectionState} />

        {joinError && (
          <div className="absolute inset-x-2 top-14 z-30 mx-auto max-w-md rounded-xl border border-red-500/30 bg-red-950/90 px-3 py-2 text-center text-xs text-red-100 shadow-lg backdrop-blur">
            {joinError}
          </div>
        )}
        </div>
      </div>

      {/* Side panel overlays the stage on small screens, sits next to it on >md */}
      <SidePanel
        open={sideOpen}
        onClose={() => setSideOpen(false)}
        eventId={eventId}
        messages={chat.messages}
        onSendChat={chat.send}
        segments={rtt.segments}
        sharedFiles={sharedFiles}
        onFileUploaded={() => void refreshFiles()}
        callType={callType}
      />

      {/* Bottom controls */}
      <ControlBar
        mode={callType}
        micOn={micOn}
        cameraOn={cameraOn}
        denoiserOn={denoiserOn}
        bgBlurOn={bgBlurOn}
        isSharing={screen.isSharing}
        recording={recording.status}
        captionsOn={captionsOn}
        translateOn={translateCaptions}
        chatOpen={sideOpen}
        chatUnread={chatUnread}
        citizenConsented={recording.consent.citizen}
        myRole={myRole}
        onToggleMic={() => setMicOn((v) => !v)}
        onToggleCamera={() => setCameraOn((v) => !v)}
        onToggleDenoiser={() => void toggleDenoiser()}
        onToggleBgBlur={() => void toggleBgBlur()}
        onToggleScreenShare={() => void toggleScreenShare()}
        onToggleRecording={() => void toggleRecording()}
        onToggleCaptions={() => void toggleCaptions()}
        onToggleTranslate={() => setTranslateCaptions((v) => !v)}
        onToggleChat={() => setSideOpen((v) => !v)}
        onEndCall={() => void endCall()}
        onSaveToVault={myRole === "user" ? () => void vault.save() : undefined}
        vaultStatus={myRole === "user" ? vault.status : undefined}
        pipSlot={
          isVideo && (
            <DocumentPipToggle
              remoteVideo={remoteVideoEl}
              onToggleMute={() => setMicOn((v) => !v)}
              onEndCall={() => void endCall()}
            />
          )
        }
      />

      {summary && (
        <EndCallSummary
          summary={summary}
          actionPlan={actionPlan}
          eventId={eventId}
          onClose={closeSummary}
          showVault={myRole === "user"}
          saveStatus={vault.status}
          saveError={vault.error}
          savedCount={vault.savedCount}
          onSaveToVault={vault.save}
          transcriptSegments={rtt.segments}
        />
      )}

      {/* Inline status when joined but no remote yet — covered by stage's
          own waiting copy, but keep this as a sanity assert on connection. */}
      {!joined && !joinError && !isChatOnly && (
        <div className="pointer-events-none absolute inset-x-0 top-1/2 z-10 -translate-y-1/2 text-center text-xs text-slate-400">
          {t("call.connecting", "Connecting…")}
        </div>
      )}
    </div>
  );
}
