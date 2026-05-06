"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo } from "react";
import { getJwt, getRoleFromJwt } from "@/lib/authToken";
import { connectSocket, getSocket } from "@/lib/socketClient";
import {
  useEmergencyStore,
  type SessionCallType,
  type SessionReadyState,
} from "@/store/useEmergencyStore";
import {
  useLawyerStore,
  type LawyerActiveAlert,
} from "@/store/useLawyerStore";

function parseEmergencyAlert(raw: unknown): LawyerActiveAlert | null {
  if (!raw || typeof raw !== "object") return null;
  const d = raw as Record<string, unknown>;
  const eventId = typeof d.eventId === "string" ? d.eventId : null;
  const loc = d.location;
  if (!eventId || !loc || typeof loc !== "object") return null;
  const lat = (loc as Record<string, unknown>).lat;
  const lng = (loc as Record<string, unknown>).lng;
  const latN = typeof lat === "number" ? lat : Number(lat);
  const lngN = typeof lng === "number" ? lng : Number(lng);
  if (!Number.isFinite(latN) || !Number.isFinite(lngN)) return null;

  const userId =
    typeof d.userId === "string"
      ? d.userId
      : d.userId != null
        ? String(d.userId)
        : null;
  const userName =
    typeof d.userName === "string" ? d.userName : "Unknown caller";
  const language = typeof d.language === "string" ? d.language : "he";
  const timestamp =
    typeof d.timestamp === "string"
      ? d.timestamp
      : new Date().toISOString();

  return {
    eventId,
    userId,
    userName,
    location: { lat: latN, lng: lngN },
    language,
    timestamp,
  };
}

function parseSessionReadyPayload(data: unknown): SessionReadyState | null {
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

export default function LawyerDashboardPage() {
  const router = useRouter();

  const isAvailable = useLawyerStore((s) => s.isAvailable);
  const activeAlert = useLawyerStore((s) => s.activeAlert);
  const isAccepting = useLawyerStore((s) => s.isAccepting);
  const lastError = useLawyerStore((s) => s.lastError);

  const setAvailable = useLawyerStore((s) => s.setAvailable);
  const setActiveAlert = useLawyerStore((s) => s.setActiveAlert);
  const setAccepting = useLawyerStore((s) => s.setAccepting);
  const setLastError = useLawyerStore((s) => s.setLastError);
  const clearAlert = useLawyerStore((s) => s.clearAlert);

  const setSessionReady = useEmergencyStore((s) => s.setSessionReady);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    const role = getRoleFromJwt();
    if (role !== "lawyer") {
      router.replace("/hub");
    }
  }, [router]);

  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;

    const sock = connectSocket();

    const syncLawyerAvailability = () => {
      const available = useLawyerStore.getState().isAvailable;
      sock.emit("lawyer_availability", { available });
    };

    if (sock.connected) {
      syncLawyerAvailability();
    } else {
      sock.once("connect", syncLawyerAvailability);
    }

    const onNewEmergency = (raw: unknown) => {
      const parsed = parseEmergencyAlert(raw);
      if (parsed) setActiveAlert(parsed);
    };

    const onCaseTaken = (raw: unknown) => {
      const eventId =
        raw &&
        typeof raw === "object" &&
        "eventId" in raw &&
        typeof (raw as { eventId?: unknown }).eventId === "string"
          ? (raw as { eventId: string }).eventId
          : null;
      const state = useLawyerStore.getState().activeAlert;
      if (eventId && state && state.eventId === eventId) {
        clearAlert();
        const msg =
          raw &&
          typeof raw === "object" &&
          "message" in raw &&
          typeof (raw as { message?: unknown }).message === "string"
            ? (raw as { message: string }).message
            : "This case is no longer available.";
        setLastError(msg);
      }
    };

    const onCaseAlreadyTaken = () => {
      setAccepting(false);
      setLastError("Another lawyer accepted this case first.");
      clearAlert();
    };

    const onVetoError = (raw: unknown) => {
      setAccepting(false);
      const msg =
        raw &&
        typeof raw === "object" &&
        "message" in raw &&
        typeof (raw as { message?: unknown }).message === "string"
          ? (raw as { message: string }).message
          : "Request failed.";
      setLastError(msg);
    };

    const onSessionReady = (raw: unknown) => {
      const session = parseSessionReadyPayload(raw);
      if (!session) {
        setAccepting(false);
        setLastError("Invalid session data from server.");
        return;
      }
      const channel = session.channelId;
      setSessionReady(session);
      setAccepting(false);
      clearAlert();
      router.push(`/call/${encodeURIComponent(channel)}`);
    };

    sock.on("new_emergency_alert", onNewEmergency);
    sock.on("case_taken", onCaseTaken);
    sock.on("case_already_taken", onCaseAlreadyTaken);
    sock.on("veto_error", onVetoError);
    sock.on("session_ready", onSessionReady);

    return () => {
      sock.off("connect", syncLawyerAvailability);
      sock.off("new_emergency_alert", onNewEmergency);
      sock.off("case_taken", onCaseTaken);
      sock.off("case_already_taken", onCaseAlreadyTaken);
      sock.off("veto_error", onVetoError);
      sock.off("session_ready", onSessionReady);
    };
  }, [
    clearAlert,
    router,
    setAccepting,
    setActiveAlert,
    setLastError,
    setSessionReady,
  ]);

  const handleAvailabilityChange = useCallback(
    (next: boolean) => {
      setAvailable(next);
      try {
        const sock = getSocket();
        if (!sock.connected) {
          sock.once("connect", () => {
            sock.emit("lawyer_availability", { available: next });
          });
          sock.connect();
        } else {
          sock.emit("lawyer_availability", { available: next });
        }
      } catch {
        connectSocket();
        const sock = getSocket();
        sock.once("connect", () => {
          sock.emit("lawyer_availability", { available: next });
        });
        if (!sock.connected) sock.connect();
      }
    },
    [setAvailable],
  );

  const formattedTime = useMemo(() => {
    if (!activeAlert) return "";
    try {
      return new Date(activeAlert.timestamp).toLocaleString();
    } catch {
      return activeAlert.timestamp;
    }
  }, [activeAlert]);

  const handleAcceptCase = () => {
    if (!activeAlert || isAccepting) return;
    setAccepting(true);
    setLastError(null);
    try {
      const sock = getSocket();
      if (!sock.connected) {
        sock.connect();
        sock.once("connect", () => {
          sock.emit("accept_case", { eventId: activeAlert.eventId });
        });
      } else {
        sock.emit("accept_case", { eventId: activeAlert.eventId });
      }
    } catch {
      connectSocket();
      const sock = getSocket();
      sock.once("connect", () => {
        sock.emit("accept_case", { eventId: activeAlert.eventId });
      });
      sock.connect();
    }
  };

  return (
    <div className="min-h-full">
      <header className="border-b border-slate-200 bg-white shadow-sm">
        <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-4 py-4 md:px-8">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-blue-600">
              VETO Legal
            </p>
            <h1 className="text-lg font-semibold text-slate-900 md:text-xl">
              Lawyer dashboard
            </h1>
          </div>
          <div className="flex items-center gap-3">
            <span
              className={`hidden text-sm font-medium sm:inline ${isAvailable ? "text-emerald-600" : "text-slate-500"}`}
            >
              {isAvailable ? "You are available" : "You are offline"}
            </span>
            <button
              type="button"
              role="switch"
              aria-checked={isAvailable}
              onClick={() => handleAvailabilityChange(!isAvailable)}
              className={`relative inline-flex h-9 w-16 shrink-0 items-center rounded-full border-2 border-transparent transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2 ${
                isAvailable ? "bg-blue-600" : "bg-slate-300"
              }`}
            >
              <span
                className={`inline-block h-7 w-7 transform rounded-full bg-white shadow transition ${
                  isAvailable ? "translate-x-8" : "translate-x-0.5"
                }`}
              />
            </button>
            <span className="text-sm font-medium text-slate-700">
              {isAvailable ? "Online" : "Offline"}
            </span>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 py-8 md:px-8">
        {lastError && (
          <div
            className="mb-6 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900"
            role="alert"
          >
            {lastError}
            <button
              type="button"
              onClick={() => setLastError(null)}
              className="ml-3 font-semibold text-amber-800 underline"
            >
              Dismiss
            </button>
          </div>
        )}

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm md:p-8">
          <h2 className="text-base font-semibold text-slate-800">
            Incoming requests
          </h2>
          <p className="mt-1 text-sm text-slate-600">
            Turn <strong>Online</strong> to receive emergency alerts. When a
            citizen triggers SOS, the case appears below — accept to join the
            Agora call when the session is ready.
          </p>

          {!activeAlert && (
            <div className="mt-10 flex flex-col items-center justify-center rounded-xl border border-dashed border-slate-200 bg-slate-50/80 py-16 text-center">
              <p className="text-slate-600">No active emergency.</p>
              <p className="mt-2 max-w-md text-sm text-slate-500">
                {isAvailable
                  ? "Waiting for incoming SOS alerts…"
                  : "Go online to receive alerts."}
              </p>
            </div>
          )}
        </div>
      </main>

      {activeAlert && (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-slate-900/60 p-4 sm:items-center sm:p-6"
          role="dialog"
          aria-modal="true"
          aria-labelledby="incoming-emergency-title"
        >
          <div className="w-full max-w-lg overflow-hidden rounded-2xl border-2 border-red-200 bg-white shadow-2xl shadow-red-900/20 ring-4 ring-red-100 sm:max-w-xl">
            <div className="bg-gradient-to-r from-red-600 to-red-500 px-6 py-4">
              <p className="text-xs font-bold uppercase tracking-widest text-red-100">
                SOS
              </p>
              <h2
                id="incoming-emergency-title"
                className="mt-1 text-2xl font-bold text-white md:text-3xl"
              >
                Incoming emergency
              </h2>
              <p className="mt-1 text-sm text-red-100">{formattedTime}</p>
            </div>
            <div className="space-y-4 px-6 py-6">
              <div className="rounded-xl bg-slate-50 p-4">
                <dl className="grid gap-3 text-sm">
                  <div className="flex justify-between gap-4">
                    <dt className="font-medium text-slate-500">Caller</dt>
                    <dd className="text-right font-semibold text-slate-900">
                      {activeAlert.userName}
                    </dd>
                  </div>
                  <div className="flex justify-between gap-4">
                    <dt className="font-medium text-slate-500">Event ID</dt>
                    <dd className="font-mono text-right text-xs text-slate-800">
                      {activeAlert.eventId}
                    </dd>
                  </div>
                  <div className="flex justify-between gap-4">
                    <dt className="font-medium text-slate-500">Language</dt>
                    <dd className="text-right text-slate-900">
                      {activeAlert.language}
                    </dd>
                  </div>
                  <div className="flex justify-between gap-4">
                    <dt className="font-medium text-slate-500">Location</dt>
                    <dd className="text-right text-slate-900">
                      {activeAlert.location.lat.toFixed(5)},{" "}
                      {activeAlert.location.lng.toFixed(5)}
                    </dd>
                  </div>
                </dl>
              </div>
              <button
                type="button"
                disabled={isAccepting}
                onClick={handleAcceptCase}
                className="w-full rounded-xl bg-blue-600 py-4 text-center text-lg font-bold text-white shadow-lg transition hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-70"
              >
                {isAccepting ? "Accepting…" : "Accept case"}
              </button>
              <p className="text-center text-xs text-slate-500">
                After the citizen chooses video or audio, you will join the call
                automatically.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
