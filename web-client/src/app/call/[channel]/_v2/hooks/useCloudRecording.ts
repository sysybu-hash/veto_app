"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { apiUrl, authFetch } from "@/api/apiClient";

export type RecordingStatus =
  | "idle"
  | "starting"
  | "recording"
  | "stopping"
  | "stopped"
  | "error";

export type ConsentSnapshot = {
  citizen: boolean;
  lawyer: boolean;
  bothGranted: boolean;
};

/**
 * Drives Agora Cloud Recording lifecycle from the v2 call UI.
 *
 *  - Only the citizen (event owner) may consent; recording is allowed once
 *    they grant consent (`bothGranted` in API payloads means citizen-only).
 *  - We poll every ~10s while recording so the indicator stays accurate.
 */
export function useCloudRecording(
  eventId: string | null,
  opts?: { wantVideo?: boolean },
) {
  const wantVideo = !!opts?.wantVideo;
  const [status, setStatus] = useState<RecordingStatus>("idle");
  const [consent, setConsent] = useState<ConsentSnapshot>({
    citizen: false,
    lawyer: false,
    bothGranted: false,
  });
  const [error, setError] = useState<string | null>(null);
  const pollTimer = useRef<number | null>(null);
  const stopInFlight = useRef(false);

  const refreshConsent = useCallback(async () => {
    if (!eventId) return;
    try {
      const res = await authFetch(apiUrl(`/api/calls/${eventId}`));
      if (!res.ok) return;
      const data = (await res.json()) as {
        call?: {
          recording_consent?: {
            citizen_at?: string | null;
            lawyer_at?: string | null;
          };
          agora_cloud_recording_resource_id?: string | null;
          recording_url?: string | null;
        };
      };
      const callDoc = data.call ?? {};
      const citizen = !!callDoc.recording_consent?.citizen_at;
      const lawyer = !!callDoc.recording_consent?.lawyer_at;
      setConsent({ citizen, lawyer, bothGranted: citizen });
      // Derive status from server state — if a resource id exists we're
      // mid-recording; if a recording_url is present we've stopped.
      if (callDoc.agora_cloud_recording_resource_id) {
        setStatus((s) => (s === "starting" || s === "stopping" ? s : "recording"));
      } else if (callDoc.recording_url) {
        setStatus((s) => (s === "starting" || s === "recording" ? "stopped" : s));
      }
    } catch {
      /* network blip — leave state alone */
    }
  }, [eventId]);

  const recordOwnConsent = useCallback(
    async (granted: boolean) => {
      if (!eventId) return;
      try {
        const res = await authFetch(apiUrl(`/api/calls/${eventId}/consent`), {
          method: "POST",
          body: JSON.stringify({ granted }),
        });
        if (!res.ok) {
          const detail = await res.text().catch(() => "");
          const hint =
            res.status === 404
              ? " — אירוע לא נמצא בשרת (וודא ש-Render מעודכן ושמזהה האירוע תואם ל-Mongo)."
              : "";
          setError(
            `Consent failed (${res.status})${hint}${detail ? ` ${detail.slice(0, 160)}` : ""}`,
          );
          return;
        }
        const data = (await res.json()) as { consent?: ConsentSnapshot };
        if (data.consent) setConsent(data.consent);
      } catch (err) {
        setError(err instanceof Error ? err.message : String(err));
      }
    },
    [eventId],
  );

  const start = useCallback(async () => {
    if (!eventId) return;
    if (!consent.citizen) {
      setError("Citizen must consent before recording starts.");
      return;
    }
    setStatus("starting");
    setError(null);
    try {
      const res = await authFetch(
        apiUrl(`/api/calls/${eventId}/cloud-recording/start`),
        {
          method: "POST",
          body: JSON.stringify({ wantVideo }),
        },
      );
      if (!res.ok) {
        setStatus("error");
        setError(`Recording start failed (${res.status})`);
        return;
      }
      setStatus("recording");
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : String(err));
    }
  }, [eventId, consent.citizen, wantVideo]);

  const stop = useCallback(async () => {
    // Guard against duplicate calls racing in (e.g. a double-click on "end
    // call" reading a stale `status` from the closure before the first call's
    // `setStatus("stopping")` has re-rendered) — Agora rejects a second stop
    // on an already-stopping mix, which used to surface as a 500 in the logs.
    if (!eventId || stopInFlight.current) return;
    stopInFlight.current = true;
    setStatus("stopping");
    try {
      const res = await authFetch(
        apiUrl(`/api/calls/${eventId}/cloud-recording/stop`),
        { method: "POST" },
      );
      setStatus(res.ok ? "stopped" : "error");
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      stopInFlight.current = false;
    }
  }, [eventId]);

  // Granting consent used to only flip a flag on the server — nothing then called
  // start(), so a citizen who clicked "I consent to recording" saw no recording
  // actually begin until someone separately found and clicked a different toggle.
  // Consenting should mean "start recording now".
  useEffect(() => {
    if (!consent.citizen || status !== "idle") return;
    queueMicrotask(() => {
      void start();
    });
  }, [consent.citizen, status, start]);

  useEffect(() => {
    if (!eventId) return;
    queueMicrotask(() => {
      void refreshConsent();
    });
    if (status === "recording") {
      pollTimer.current = window.setInterval(() => void refreshConsent(), 10_000);
      return () => {
        if (pollTimer.current) window.clearInterval(pollTimer.current);
        pollTimer.current = null;
      };
    }
    return undefined;
  }, [eventId, status, refreshConsent]);

  return { status, consent, error, start, stop, recordOwnConsent, refreshConsent };
}
