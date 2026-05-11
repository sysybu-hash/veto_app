"use client";

import { useTrWithFallback } from "../lib/trWithFallback";
import type { ActionPlan } from "@/api/advancedApi";
import { createOvertimeOrder } from "@/api/paymentApi";

export type SummaryShape = {
  minutes: number;
  base: number;
  overtime: number;
  total: number;
  status?: string;
};

function stepKindLabel(
  action: string,
  t: (k: string, fb: string) => string,
): string {
  switch (action) {
    case "payment":
      return t("call.v2.summary.stepPayment", "Payment");
    case "vault":
      return t("call.v2.summary.stepVault", "Vault & evidence");
    case "document_generator":
      return t("call.v2.summary.stepDoc", "Documents");
    case "calendar":
      return t("call.v2.summary.stepCalendar", "Follow-up");
    default:
      return t("call.v2.summary.stepOther", "Next step");
  }
}

export function EndCallSummary({
  summary,
  actionPlan,
  eventId,
  onClose,
  showVault = true,
  saveStatus,
  saveError,
  savedCount,
  onSaveToVault,
}: {
  summary: SummaryShape;
  actionPlan: ActionPlan | null;
  eventId: string | null;
  onClose: () => void;
  showVault?: boolean;
  saveStatus: "idle" | "saving" | "saved" | "error";
  saveError: string | null;
  savedCount: number;
  onSaveToVault: () => void;
}) {
  const t = useTrWithFallback();

  const vaultButtonLabel =
    saveStatus === "saving"
      ? t("call.v2.summary.vaultSaving", "Saving…")
      : saveStatus === "saved"
        ? savedCount > 0
          ? `${t("call.v2.summary.vaultSaved", "Saved")} (${savedCount})`
          : t("call.v2.summary.vaultSavedMongo", "Saved to your vault")
        : t("call.v2.summary.vaultBtn", "Save to vault");

  return (
    <div className="absolute inset-0 z-50 flex items-end justify-center bg-black/80 p-0 backdrop-blur-md @md:items-center @md:p-6">
      <div
        className="flex max-h-[min(92dvh,900px)] w-full max-w-lg flex-col overflow-hidden rounded-t-3xl border border-white/[0.1] bg-gradient-to-b from-zinc-900/98 to-black/98 shadow-[0_-12px_60px_rgba(0,0,0,0.55)] @md:max-h-[85vh] @md:rounded-3xl @md:border-[#C5A059]/20 @md:shadow-2xl"
        role="dialog"
        aria-modal="true"
        aria-labelledby="call-summary-title"
      >
        <div
          className="h-1 w-12 shrink-0 self-center rounded-full bg-white/20 @md:hidden"
          aria-hidden
        />

        <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-5 pb-5 pt-4 @md:px-6 @md:pb-6 @md:pt-5">
          <div className="flex items-start justify-between gap-3">
            <h3
              id="call-summary-title"
              className="font-frank text-xl font-bold tracking-tight text-white @md:text-2xl"
            >
              {t("call.v2.summary.title", "Call summary")}
            </h3>
            <span className="shrink-0 rounded-full border border-[#C5A059]/35 bg-[#C5A059]/10 px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-[#C5A059]">
              VETO
            </span>
          </div>

          <div className="mt-5 grid gap-2 rounded-2xl border border-white/[0.06] bg-white/[0.03] p-4">
            <Row
              label={t("call.v2.summary.duration", "Duration")}
              value={`${summary.minutes} ${t("call.v2.summary.minutes", "min")}`}
            />
            <Row
              label={t("call.v2.summary.base", "Base rate")}
              value={`₪${summary.base.toFixed(2)}`}
            />
            <Row
              label={t("call.v2.summary.overtime", "Overtime")}
              value={`₪${summary.overtime.toFixed(2)}`}
            />
            <div className="mt-1 flex items-center justify-between border-t border-white/10 pt-3">
              <span className="text-sm font-semibold text-slate-300">
                {t("call.v2.summary.total", "Total to bill")}
              </span>
              <span className="text-lg font-bold tabular-nums text-[#C5A059]">
                ₪{summary.total.toFixed(2)}
              </span>
            </div>
          </div>

          {actionPlan && (
            <section className="mt-5 rounded-2xl border border-[#C5A059]/20 bg-[#C5A059]/[0.06] p-4">
              <p className="text-sm font-bold text-[#C5A059]">
                {t("call.v2.summary.planTitle", "Legal action plan")}
              </p>
              <p className="mt-2 text-xs leading-relaxed text-slate-300">
                {actionPlan.ai.disclosure}
              </p>
              <ol className="mt-4 space-y-2">
                {actionPlan.steps.map((step, i) => (
                  <li
                    key={step.key}
                    className="flex gap-3 rounded-xl border border-white/[0.06] bg-black/30 px-3 py-2.5"
                  >
                    <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-[#C5A059]/20 text-xs font-bold text-[#C5A059]">
                      {i + 1}
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium leading-snug text-white">
                        {step.title}
                      </p>
                      <p className="mt-0.5 text-[11px] text-slate-500">
                        {stepKindLabel(step.action, t)}
                      </p>
                    </div>
                  </li>
                ))}
              </ol>
            </section>
          )}

          {showVault && (
            <section className="mt-5 rounded-2xl border border-emerald-500/25 bg-emerald-950/25 p-4">
              <p className="text-sm font-bold text-emerald-100">
                {t("call.v2.summary.vaultTitle", "Save to my vault")}
              </p>
              <p className="mt-1.5 text-xs leading-relaxed text-emerald-100/75">
                {t(
                  "call.v2.summary.vaultBody",
                  "Recording + transcript are kept on VETO servers; this pins them to your vault and timeline.",
                )}
              </p>
              <div className="mt-4 flex flex-col gap-2 @sm:flex-row @sm:items-center @sm:justify-between">
                <button
                  type="button"
                  onClick={onSaveToVault}
                  disabled={saveStatus === "saving" || saveStatus === "saved"}
                  className="inline-flex min-h-[44px] items-center justify-center rounded-xl bg-emerald-500 px-4 text-sm font-bold text-emerald-950 shadow-lg shadow-emerald-900/30 transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {vaultButtonLabel}
                </button>
                {saveStatus === "error" && saveError && (
                  <p className="text-xs leading-snug text-red-300 @sm:max-w-[55%] @sm:text-end">
                    {saveError}
                  </p>
                )}
              </div>
            </section>
          )}

          <div className="mt-6 flex flex-col-reverse gap-2 @sm:flex-row @sm:justify-end @sm:gap-3">
            <button
              type="button"
              onClick={onClose}
              className="min-h-[44px] rounded-xl border border-white/15 bg-white/[0.05] px-5 text-sm font-semibold text-slate-100 transition hover:bg-white/10"
            >
              {t("call.v2.summary.close", "Close")}
            </button>
            {summary.overtime > 0 && (
              <button
                type="button"
                onClick={async () => {
                  try {
                    const r = await createOvertimeOrder(
                      summary.minutes,
                      eventId ?? undefined,
                    );
                    window.location.assign(r.approveUrl);
                  } catch {
                    onClose();
                  }
                }}
                className="min-h-[44px] rounded-xl bg-[#C5A059] px-5 text-sm font-bold text-black shadow-md transition hover:brightness-110"
              >
                {t("call.v2.summary.payCta", "Confirm & pay")} ₪
                {summary.overtime.toFixed(2)}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 text-sm">
      <span className="text-slate-400">{label}</span>
      <span className="tabular-nums text-slate-100">{value}</span>
    </div>
  );
}
