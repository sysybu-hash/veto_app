"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect } from "react";
import { triggerSosAlert } from "@/app/actions/sos";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { btnSecondaryGlass } from "@/lib/vetoGlass";
import { getJwt } from "@/lib/authToken";
import { connectSocket, getSocket } from "@/lib/socketClient";
import {
  useEmergencyStore,
  type SessionCallType,
  type SessionReadyState,
} from "@/store/useEmergencyStore";

const DEFAULT_LOCATION = { lat: 32.0853, lng: 34.7818 };

function readSessionPayload(data: unknown): SessionReadyState | null {
  if (!data || typeof data !== "object") return null;
  const d = data as Record<string, unknown>;
  const roomId = typeof d.roomId === "string" ? d.roomId : null;
  const eventId = typeof d.eventId === "string" ? d.eventId : null;
  const agoraToken = typeof d.agoraToken === "string" ? d.agoraToken : null;
  const agoraUidRaw = d.agoraUid;
  const agoraUid =
    typeof agoraUidRaw === "number"
      ? agoraUidRaw
      : typeof agoraUidRaw === "string" && agoraUidRaw !== ""
        ? Number(agoraUidRaw)
        : NaN;
  const callTypeRaw = d.callType;
  const callType: SessionCallType =
    callTypeRaw === "audio" || callTypeRaw === "chat" || callTypeRaw === "video"
      ? callTypeRaw
      : "video";
  const tokenExpiresAt =
    typeof d.tokenExpiresAt === "number" ? d.tokenExpiresAt : undefined;

  if (!roomId || !eventId || !agoraToken || !Number.isFinite(agoraUid)) {
    return null;
  }

  return {
    channelId: roomId,
    eventId,
    token: agoraToken,
    uid: agoraUid,
    callType,
    tokenExpiresAt,
  };
}

export default function CitizenHubPage() {
  const router = useRouter();

  const isSearching = useEmergencyStore((s) => s.isSearching);
  const lawyerFound = useEmergencyStore((s) => s.lawyerFound);
  const lawyerName = useEmergencyStore((s) => s.lawyerName);
  const statusMessage = useEmergencyStore((s) => s.statusMessage);

  const reset = useEmergencyStore((s) => s.reset);
  const startSearch = useEmergencyStore((s) => s.startSearch);
  const setLawyerFound = useEmergencyStore((s) => s.setLawyerFound);
  const setSessionReady = useEmergencyStore((s) => s.setSessionReady);
  const setErrorMessage = useEmergencyStore((s) => s.setErrorMessage);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
    }
  }, [router]);

  useEffect(() => {
    if (!getJwt()) return;

    let cancelled = false;
    const sock = connectSocket();

    const onConnect = () => {
      if (cancelled) return;
      console.info("[hub] socket connected");
    };

    const onLawyerFound = (raw: unknown) => {
      if (cancelled) return;
      const payload =
        raw && typeof raw === "object" ? (raw as Record<string, unknown>) : null;
      const eventId = typeof payload?.eventId === "string" ? payload.eventId : null;
      const roomId = typeof payload?.roomId === "string" ? payload.roomId : null;
      const name =
        typeof payload?.lawyerName === "string" ? payload.lawyerName : undefined;
      if (!eventId || !roomId) {
        useEmergencyStore.getState().setErrorMessage("Invalid lawyer_found payload.");
        return;
      }
      setLawyerFound({ eventId, roomId, lawyerName: name });
      sock.emit("citizen_chose_session", { eventId, callType: "video" as const });
    };

    const onSessionReady = (raw: unknown) => {
      if (cancelled) return;
      const parsed = readSessionPayload(raw);
      if (!parsed) {
        setErrorMessage("Could not start call (missing session data).");
        return;
      }
      setSessionReady(parsed);
      router.push(`/call/${encodeURIComponent(parsed.channelId)}`);
    };

    const onNoLawyers = () => {
      if (cancelled) return;
      setErrorMessage("No lawyers are available right now. Try again shortly.");
    };

    const onVetoError = (raw: unknown) => {
      if (cancelled) return;
      const msg =
        raw &&
        typeof raw === "object" &&
        "message" in raw &&
        typeof (raw as { message?: unknown }).message === "string"
          ? (raw as { message: string }).message
          : "Something went wrong.";
      setErrorMessage(msg);
    };

    const onCaseTaken = (raw: unknown) => {
      if (cancelled) return;
      const msg =
        raw &&
        typeof raw === "object" &&
        "message" in raw &&
        typeof (raw as { message?: unknown }).message === "string"
          ? (raw as { message: string }).message
          : "This case is no longer available.";
      const { isSearching: searching, lawyerFound: found } =
        useEmergencyStore.getState();
      if (searching || found) {
        setErrorMessage(msg);
      }
    };

    sock.on("connect", onConnect);
    sock.on("lawyer_found", onLawyerFound);
    sock.on("session_ready", onSessionReady);
    sock.on("no_lawyers_available", onNoLawyers);
    sock.on("veto_error", onVetoError);
    sock.on("case_taken", onCaseTaken);

    return () => {
      cancelled = true;
      sock.off("connect", onConnect);
      sock.off("lawyer_found", onLawyerFound);
      sock.off("session_ready", onSessionReady);
      sock.off("no_lawyers_available", onNoLawyers);
      sock.off("veto_error", onVetoError);
      sock.off("case_taken", onCaseTaken);
    };
  }, [router, setErrorMessage, setLawyerFound, setSessionReady]);

  const handleSos = useCallback(() => {
    if (!getJwt()) {
      router.push("/login");
      return;
    }

    startSearch();
    setErrorMessage(null);

    const sock = (() => {
      try {
        return getSocket();
      } catch {
        return connectSocket();
      }
    })();

    if (!sock.connected) {
      sock.connect();
    }

    const emitStart = (lat: number, lng: number, accuracy?: number) => {
      sock.emit("start_veto", {
        location: { lat, lng },
        preferredLanguage: "he",
      });
      void triggerSosAlert({
        location:
          typeof accuracy === "number" && Number.isFinite(accuracy)
            ? { lat, lng, accuracy }
            : { lat, lng },
        stress_test: false,
        urgency: "SOS",
      }).then((r) => {
        if (!r.success) {
          console.warn("[hub] Ably SOS:", r.error);
        }
      });
    };

    if (typeof navigator === "undefined" || !navigator.geolocation) {
      emitStart(DEFAULT_LOCATION.lat, DEFAULT_LOCATION.lng);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        emitStart(
          pos.coords.latitude,
          pos.coords.longitude,
          pos.coords.accuracy,
        );
      },
      () => {
        emitStart(DEFAULT_LOCATION.lat, DEFAULT_LOCATION.lng);
      },
      { enableHighAccuracy: true, timeout: 12_000, maximumAge: 60_000 },
    );
  }, [router, setErrorMessage, startSearch]);

  return (
    <>
    <main className="mx-auto flex w-full max-w-lg flex-1 flex-col items-center justify-center gap-8 px-6 py-12 pb-28">
      <div className="w-full rounded-2xl border border-white/50 bg-white/55 px-5 py-6 text-center shadow-sm backdrop-blur-xl">
        <h1 className="font-frank text-2xl font-bold text-slate-900">
          Emergency legal help
        </h1>
        <p className="mt-2 text-sm text-slate-600">
          Tap SOS to request a lawyer. Stay on this screen until the call opens.
        </p>
      </div>

      <button
        type="button"
        onClick={handleSos}
        disabled={isSearching}
        className="sos-btn relative flex h-44 w-44 items-center justify-center rounded-full border-4 border-red-950 bg-red-700 text-lg font-bold text-white shadow-2xl shadow-red-900/50 transition enabled:cursor-pointer enabled:hover:bg-red-600 enabled:active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-70"
      >
        <span className="relative z-10">SOS</span>
      </button>

      {isSearching && !lawyerFound && (
        <p className="text-center text-sm font-medium text-amber-800">
          Searching for an available lawyer…
        </p>
      )}

      {lawyerFound && lawyerName && (
        <p className="text-center text-sm font-medium text-emerald-800">
          {lawyerName} accepted — starting your video session…
        </p>
      )}

      {statusMessage && (
        <div
          role="alert"
          className="w-full rounded-xl border border-red-300/80 bg-red-50/90 px-4 py-3 text-center text-sm text-red-900 backdrop-blur-md"
        >
          {statusMessage}
          <div className="mt-3">
            <button
              type="button"
              onClick={() => reset()}
              className={`${btnSecondaryGlass} px-3 py-1.5 text-xs`}
            >
              Dismiss
            </button>
          </div>
        </div>
      )}
    </main>

      <CitizenBottomNav active="hub" />
    </>
  );
}
