"use client";

import { btnSecondaryGlass, glassPanel, glassPanelNested } from "@/lib/vetoGlass";

export default function SettingsBillingPage() {
  return (
    <div className="flex flex-col gap-5">
      <section className={`${glassPanel} p-5`}>
        <h2 className="font-frank text-lg font-bold text-slate-900">
          Subscription status
        </h2>
        <p className="font-heebo mt-1 text-sm text-slate-600">
          Your plan and upgrade options. PayPal checkout will connect here.
        </p>

        <div
          className="mt-5 rounded-2xl border border-white/50 bg-linear-to-br from-white/50 to-white/35 p-5 shadow-[0_0_32px_rgba(197,160,89,0.12)] backdrop-blur-xl"
        >
          <p className="font-heebo text-xs font-bold uppercase tracking-wider text-[#8a6d3d]">
            Current plan
          </p>
          <p className="font-frank mt-2 text-2xl font-bold text-slate-900">
            VETO Free
          </p>
          <p className="font-heebo mt-2 text-sm text-slate-600">
            Core protection and vault access. Upgrade for priority routing and
            advanced tools.
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            <span className="font-heebo rounded-full border border-[#C5A059]/40 bg-[#C5A059]/15 px-3 py-1 text-xs font-semibold text-slate-800">
              Active
            </span>
            <span className="font-heebo rounded-full border border-white/45 bg-white/30 px-3 py-1 text-xs text-slate-700 backdrop-blur-sm">
              Renews — TBD
            </span>
          </div>
        </div>

        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <div className={`flex flex-col p-4 ${glassPanelNested}`}>
            <h3 className="font-frank text-lg font-bold text-slate-900">
              VETO Pro
            </h3>
            <p className="font-heebo mt-2 text-sm text-slate-600">
              Faster lawyer matching, expanded vault, and priority support.
            </p>
            <p className="font-frank mt-3 text-sm font-bold text-[#8a6d3d]">
              Coming soon
            </p>
          </div>
          <div className={`flex flex-col p-4 ${glassPanelNested}`}>
            <h3 className="font-frank text-lg font-bold text-slate-900">
              VETO Enterprise
            </h3>
            <p className="font-heebo mt-2 text-sm text-slate-600">
              Teams, compliance, and dedicated success for firms.
            </p>
            <p className="font-frank mt-3 text-sm font-bold text-[#8a6d3d]">
              Contact sales
            </p>
          </div>
        </div>

        <div
          className={`mt-4 flex flex-col gap-3 border border-dashed border-white/50 px-4 py-6 text-center backdrop-blur-md ${glassPanelNested}`}
        >
          <span
            className="font-heebo text-xs font-bold tracking-widest text-slate-500"
            aria-hidden
          >
            PayPal
          </span>
          <p className="font-heebo text-xs font-medium text-slate-600">
            Secure checkout — integration in progress
          </p>
          <button
            type="button"
            disabled
            className={`font-heebo mx-auto cursor-not-allowed px-5 py-2.5 text-xs opacity-55 ${btnSecondaryGlass}`}
          >
            Connect PayPal
          </button>
        </div>
      </section>
    </div>
  );
}
