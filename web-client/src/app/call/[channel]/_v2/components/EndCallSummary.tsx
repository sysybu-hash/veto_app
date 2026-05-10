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

export function EndCallSummary({
  summary,
  actionPlan,
  eventId,
  onClose,
  saveStatus,
  saveError,
  savedCount,
  onSaveToVault,
}: {
  summary: SummaryShape;
  actionPlan: ActionPlan | null;
  eventId: string | null;
  onClose: () => void;
  saveStatus: "idle" | "saving" | "saved" | "error";
  saveError: string | null;
  savedCount: number;
  onSaveToVault: () => void;
}) {
  const t = useTrWithFallback();

  return (
    <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/85 p-4 backdrop-blur-sm">
      <div className="w-full max-w-md rounded-2xl border border-white/10 bg-slate-900 p-5 text-slate-100 shadow-2xl">
        <h3 className="font-frank text-xl font-bold">
          {t("call.v2.summary.title", "Call summary")}
        </h3>
        <dl className="mt-4 space-y-2 text-sm">
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
          <div className="mt-3 flex justify-between border-t border-white/10 pt-3 text-base font-bold text-amber-300">
            <dt>{t("call.v2.summary.total", "Total to bill")}</dt>
            <dd>₪{summary.total.toFixed(2)}</dd>
          </div>
        </dl>

        {actionPlan && (
          <section className="mt-4 rounded-2xl border border-white/10 bg-white/[0.04] p-3">
            <p className="text-sm font-bold text-amber-200">
              {t("call.v2.summary.planTitle", "Legal action plan")}
            </p>
            <p className="mt-1 text-[11px] leading-5 text-slate-400">
              {actionPlan.ai.disclosure}
            </p>
            <ul className="mt-2 space-y-1.5 text-sm">
              {actionPlan.steps.map((step) => (
                <li
                  key={step.key}
                  className="flex items-center justify-between gap-2 rounded-lg bg-white/[0.04] px-2 py-1.5"
                >
                  <span>{step.title}</span>
                  <span className="text-[11px] text-slate-400">{step.action}</span>
                </li>
              ))}
            </ul>
          </section>
        )}

        <section className="mt-4 rounded-2xl border border-emerald-500/30 bg-emerald-950/30 p-3">
          <p className="text-sm font-bold text-emerald-200">
            {t("call.v2.summary.vaultTitle", "Save to my vault")}
          </p>
          <p className="mt-1 text-[11px] leading-5 text-emerald-100/80">
            {t(
              "call.v2.summary.vaultBody",
              "Recording + transcript become signed evidence in your private vault.",
            )}
          </p>
          <div className="mt-3 flex items-center gap-2">
            <button
              type="button"
              onClick={onSaveToVault}
              disabled={saveStatus === "saving" || saveStatus === "saved"}
              className="rounded-xl bg-emerald-500 px-3 py-1.5 text-xs font-bold text-emerald-950 hover:bg-emerald-400 disabled:opacity-50"
            >
              {saveStatus === "saving"
                ? t("call.v2.summary.vaultSaving", "Saving…")
                : saveStatus === "saved"
                  ? t("call.v2.summary.vaultSaved", `Saved (${savedCount})`)
                  : t("call.v2.summary.vaultBtn", "Save to vault")}
            </button>
            {saveStatus === "error" && saveError && (
              <span className="text-[11px] text-red-300">{saveError}</span>
            )}
          </div>
        </section>

        <div className="mt-5 flex justify-between gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl border border-white/10 bg-white/[0.04] px-4 py-2 text-sm font-semibold text-slate-200"
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
              className="rounded-xl bg-[#C5A059] px-5 py-2 text-sm font-bold text-black"
            >
              {t("call.v2.summary.payCta", "Confirm & pay")} ₪
              {summary.overtime.toFixed(2)}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <dt className="text-slate-400">{label}</dt>
      <dd>{value}</dd>
    </div>
  );
}
