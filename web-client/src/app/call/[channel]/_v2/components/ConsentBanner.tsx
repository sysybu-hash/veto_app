"use client";

import { useEffect, useState } from "react";
import { useTrWithFallback } from "../lib/trWithFallback";
import type { ConsentSnapshot } from "../hooks/useCloudRecording";

/**
 * GDPR consent strip — appears at the top of the call surface until the
 * current user has given (or refused) consent for cloud recording. The
 * recording control in ControlBar stays disabled until both sides accept.
 */
export function ConsentBanner({
  consent,
  myConsent,
  onChoose,
  myRole,
}: {
  consent: ConsentSnapshot;
  /** `true` if I've already granted; `false` if denied; `null` = undecided. */
  myConsent: boolean | null;
  onChoose: (granted: boolean) => void;
  myRole: "user" | "lawyer";
}) {
  const t = useTrWithFallback();
  const [collapsed, setCollapsed] = useState(false);

  // Re-show if consent changes server-side after a user already collapsed.
  useEffect(() => {
    if (!consent.bothGranted && myConsent === true) {
      queueMicrotask(() => setCollapsed(true));
    }
  }, [consent.bothGranted, myConsent]);

  if (myConsent !== null && (collapsed || consent.bothGranted)) {
    return (
      <div
        className="pointer-events-none absolute inset-x-0 top-0 z-30 flex justify-center pt-2"
        role="status"
        aria-live="polite"
      >
        <span
          className={`pointer-events-auto rounded-full border px-3 py-1 text-[11px] font-semibold backdrop-blur ${
            consent.bothGranted
              ? "border-emerald-500/40 bg-emerald-950/60 text-emerald-200"
              : "border-amber-500/40 bg-amber-950/60 text-amber-200"
          }`}
        >
          {consent.bothGranted
            ? t(
                "call.v2.consent.bothOk",
                "Both parties consented — recording allowed.",
              )
            : t(
                "call.v2.consent.waiting",
                "Waiting for the other side to consent to recording.",
              )}
        </span>
      </div>
    );
  }

  return (
    <div
      role="alertdialog"
      aria-modal="false"
      className="absolute inset-x-2 top-2 z-30 rounded-2xl border border-amber-500/40 bg-slate-950/90 p-4 text-sm text-slate-100 shadow-xl backdrop-blur md:inset-x-auto md:left-1/2 md:max-w-lg md:-translate-x-1/2"
    >
      <p className="font-semibold text-amber-200">
        {t("call.v2.consent.title", "Cloud recording consent (GDPR)")}
      </p>
      <p className="mt-1 text-xs leading-5 text-slate-300">
        {myRole === "user"
          ? t(
              "call.v2.consent.bodyCitizen",
              "Recording is encrypted and stored only in your private vault. Both sides must consent before recording starts.",
            )
          : t(
              "call.v2.consent.bodyLawyer",
              "Recording is stored only in the citizen's vault. Both sides must consent before recording starts.",
            )}
      </p>
      <div className="mt-3 flex flex-wrap justify-end gap-2">
        <button
          type="button"
          onClick={() => onChoose(false)}
          className="rounded-lg border border-white/10 bg-white/[0.04] px-3 py-1.5 text-xs font-semibold text-slate-200 hover:bg-white/[0.08]"
        >
          {t("call.v2.consent.decline", "Decline")}
        </button>
        <button
          type="button"
          onClick={() => onChoose(true)}
          className="rounded-lg bg-[#C5A059] px-3 py-1.5 text-xs font-bold text-black hover:bg-[#D8B867]"
        >
          {t("call.v2.consent.accept", "I consent to recording")}
        </button>
      </div>
    </div>
  );
}
