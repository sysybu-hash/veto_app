"use client";

import { useEffect, useMemo, useState } from "react";
import { useTrWithFallback } from "../lib/trWithFallback";
import { useAgoraDevices } from "../hooks/useAgoraDevices";

type Mode = "video" | "audio" | "chat";

export type PreCallReadiness = {
  micId: string | null;
  cameraId: string | null;
  speakerId: string | null;
  ready: boolean;
};

/**
 * Pre-call lobby — one-shot device picker + permission gate.
 * Renders nothing once `onReady` has been called.
 */
export function PreCallCheck({
  mode,
  onReady,
}: {
  mode: Mode;
  onReady: (r: PreCallReadiness) => void;
}) {
  const t = useTrWithFallback();
  const {
    devices,
    selectedMicId,
    selectedCameraId,
    selectedSpeakerId,
    permission,
    requestPermission,
    chooseMic,
    chooseCamera,
    chooseSpeaker,
  } = useAgoraDevices();

  const [latencyMs, setLatencyMs] = useState<number | null>(null);
  const [latencyChecking, setLatencyChecking] = useState(false);

  const needsMic = mode !== "chat";
  const needsCamera = mode === "video";

  const canStart = useMemo(() => {
    if (needsMic && devices.microphones.length === 0) return false;
    if (needsCamera && devices.cameras.length === 0) return false;
    if ((needsMic || needsCamera) && permission !== "granted") return false;
    return true;
  }, [needsMic, needsCamera, devices, permission]);

  useEffect(() => {
    if (mode === "chat") {
      // No mic/cam needed — proceed immediately.
      onReady({
        micId: null,
        cameraId: null,
        speakerId: null,
        ready: true,
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode]);

  const checkNetwork = async () => {
    setLatencyChecking(true);
    const start = performance.now();
    try {
      // Hit a small static asset on the same origin to estimate latency.
      const res = await fetch("/favicon.ico", { cache: "no-store" });
      await res.arrayBuffer().catch(() => undefined);
      setLatencyMs(Math.round(performance.now() - start));
    } catch {
      setLatencyMs(null);
    } finally {
      setLatencyChecking(false);
    }
  };

  if (mode === "chat") return null;

  return (
    <div className="veto-call-keep-dark fixed inset-0 z-[80] flex items-center justify-center bg-black/85 px-4 py-8 backdrop-blur-md">
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="pre-call-title"
        className="w-full max-w-md rounded-2xl border border-white/10 bg-slate-950/90 p-5 text-slate-100 shadow-2xl"
      >
        <h2 id="pre-call-title" className="font-frank text-xl font-bold">
          {t("call.v2.preCheck.title", "Ready your call")}
        </h2>
        <p className="mt-1 text-xs text-slate-400">
          {t(
            "call.v2.preCheck.subtitle",
            "Pick the right mic, camera, and speaker before connecting.",
          )}
        </p>

        {permission !== "granted" && (
          <button
            type="button"
            onClick={() =>
              void requestPermission({ mic: needsMic, camera: needsCamera })
            }
            className="mt-4 w-full rounded-xl bg-[#C5A059] px-4 py-2 text-sm font-bold text-black hover:bg-[#D8B867]"
          >
            {t("call.v2.preCheck.grant", "Allow microphone & camera")}
          </button>
        )}

        {permission === "denied" && (
          <p className="mt-3 rounded-lg bg-red-950/70 px-3 py-2 text-xs text-red-200">
            {t(
              "call.v2.preCheck.denied",
              "Browser denied access. Open the site permissions and try again.",
            )}
          </p>
        )}

        {needsMic && (
          <DeviceSelect
            label={t("call.v2.preCheck.mic", "Microphone")}
            value={selectedMicId ?? ""}
            onChange={(v) => chooseMic(v || null)}
            options={devices.microphones}
          />
        )}
        {needsCamera && (
          <DeviceSelect
            label={t("call.v2.preCheck.camera", "Camera")}
            value={selectedCameraId ?? ""}
            onChange={(v) => chooseCamera(v || null)}
            options={devices.cameras}
          />
        )}
        {needsMic && devices.speakers.length > 0 && (
          <DeviceSelect
            label={t("call.v2.preCheck.speaker", "Speaker")}
            value={selectedSpeakerId ?? ""}
            onChange={(v) => chooseSpeaker(v || null)}
            options={devices.speakers}
          />
        )}

        <div className="mt-4 flex items-center justify-between rounded-xl border border-white/10 bg-white/[0.04] px-3 py-2">
          <div className="text-xs text-slate-300">
            <p className="font-semibold">
              {t("call.v2.preCheck.network", "Network")}
            </p>
            <p className="text-[11px] text-slate-500">
              {latencyMs == null
                ? t(
                    "call.v2.preCheck.networkUnknown",
                    "Tap to estimate latency",
                  )
                : `${latencyMs} ms`}
            </p>
          </div>
          <button
            type="button"
            onClick={() => void checkNetwork()}
            disabled={latencyChecking}
            className="rounded-lg bg-white/10 px-3 py-1 text-xs font-semibold text-slate-100 hover:bg-white/15 disabled:opacity-50"
          >
            {latencyChecking
              ? t("call.v2.preCheck.testing", "Testing…")
              : t("call.v2.preCheck.test", "Test")}
          </button>
        </div>

        <button
          type="button"
          disabled={!canStart}
          onClick={() =>
            onReady({
              micId: selectedMicId,
              cameraId: selectedCameraId,
              speakerId: selectedSpeakerId,
              ready: true,
            })
          }
          className="mt-5 w-full rounded-xl bg-[#C5A059] px-4 py-3 text-sm font-black text-black hover:bg-[#D8B867] disabled:opacity-40"
        >
          {t("call.v2.preCheck.start", "Start the call")}
        </button>
      </div>
    </div>
  );
}

function DeviceSelect({
  label,
  value,
  onChange,
  options,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: MediaDeviceInfo[];
}) {
  return (
    <label className="mt-3 block text-xs">
      <span className="mb-1 block font-semibold text-slate-300">{label}</span>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-lg border border-white/10 bg-white/10 px-2 py-2 text-sm text-slate-100 outline-none focus:ring-2 focus:ring-[#C5A059]"
      >
        <option value="">— Default —</option>
        {options.map((d) => (
          <option key={d.deviceId} value={d.deviceId}>
            {d.label || `${d.kind} (${d.deviceId.slice(0, 6)})`}
          </option>
        ))}
      </select>
    </label>
  );
}
