"use client";

import { useTrWithFallback } from "../lib/trWithFallback";
import type { ConsentSnapshot, RecordingStatus } from "../hooks/useCloudRecording";

/**
 * GDPR / privacy strip for cloud recording.
 * - Citizen: must explicitly accept or decline; only they can enable recording in the control bar.
 * - Lawyer: read-only status — they see whether recording is active / whether the citizen has consented,
 *   but cannot grant consent or start/stop recording from here.
 */
export function ConsentBanner({
  consent,
  onChoose,
  myRole,
  recordingStatus,
}: {
  consent: ConsentSnapshot;
  onChoose: (granted: boolean) => void;
  myRole: "user" | "lawyer";
  recordingStatus: RecordingStatus;
}) {
  const t = useTrWithFallback();

  const recOn =
    recordingStatus === "recording" ||
    recordingStatus === "starting" ||
    recordingStatus === "stopping";

  if (myRole === "lawyer") {
    return (
      <div
        className="pointer-events-none absolute inset-x-0 top-0 z-30 flex justify-center pt-2"
        role="status"
        aria-live="polite"
      >
        <span
          className={`pointer-events-auto max-w-[min(100%,28rem)] rounded-full border px-3 py-1 text-center text-[11px] font-semibold leading-snug backdrop-blur ${
            recOn
              ? "border-red-500/50 bg-red-950/70 text-red-100"
              : consent.citizen
                ? "border-strong/40 bg-surface-raised/75 text-primary"
                : "border-amber-500/40 bg-amber-950/60 text-amber-100"
          }`}
        >
          {recOn
            ? t(
                "call.v2.consent.lawyerRecordingOn",
                "This call is being recorded. Only the citizen controls recording and saving.",
              )
            : consent.citizen
              ? t(
                  "call.v2.consent.lawyerCitizenConsented",
                  "The citizen has approved recording if they choose to start it. You cannot start or stop recording.",
                )
              : t(
                  "call.v2.consent.lawyerWaitingCitizen",
                  "Recording is off until the citizen approves and starts it.",
                )}
        </span>
      </div>
    );
  }

  // Citizen: compact reminder once consent is stored server-side
  if (consent.citizen) {
    return (
      <div
        className="pointer-events-none absolute inset-x-0 top-0 z-30 flex justify-center pt-2"
        role="status"
        aria-live="polite"
      >
        <span className="pointer-events-auto rounded-full border border-emerald-500/40 bg-emerald-950/60 px-3 py-1 text-[11px] font-semibold text-emerald-200 backdrop-blur">
          {t(
            "call.v2.consent.citizenOk",
            "You approved recording — use Record below to start or stop when you want.",
          )}
        </span>
      </div>
    );
  }

  return (
    <div
      role="alertdialog"
      aria-modal="false"
      className="absolute inset-x-2 top-2 z-30 rounded-2xl border border-amber-500/40 bg-surface-canvas/90 p-4 text-sm text-primary shadow-xl backdrop-blur md:inset-x-auto md:left-1/2 md:max-w-lg md:-translate-x-1/2"
    >
      <p className="font-semibold text-amber-200">
        {t("call.v2.consent.title", "Cloud recording consent (GDPR)")}
      </p>
      <p className="mt-1 text-xs leading-5 text-secondary">
        {t(
          "call.v2.consent.bodyCitizen",
          "Recording is encrypted and stored only in your private vault. You decide whether to record; the lawyer only sees a status indicator, not your vault.",
        )}
      </p>
      <div className="mt-3 flex flex-wrap justify-end gap-2">
        <button
          type="button"
          onClick={() => onChoose(false)}
          className="rounded-lg border border-subtle bg-white/[0.04] px-3 py-1.5 text-xs font-semibold text-primary hover:bg-white/[0.08]"
        >
          {t("call.v2.consent.decline", "Decline")}
        </button>
        <button
          type="button"
          onClick={() => onChoose(true)}
          className="rounded-lg bg-veto-gold px-3 py-1.5 text-xs font-bold text-black hover:bg-veto-gold-light"
        >
          {t("call.v2.consent.accept", "I consent to recording")}
        </button>
      </div>
    </div>
  );
}
