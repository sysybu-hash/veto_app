"use client";

import { useTrWithFallback } from "../lib/trWithFallback";
import type { QualityReadout } from "../hooks/useNetworkQuality";

const COLORS: Record<QualityReadout["label"], string> = {
  excellent: "bg-emerald-400",
  good: "bg-emerald-300",
  ok: "bg-amber-300",
  poor: "bg-amber-500",
  bad: "bg-red-500",
  unknown: "bg-zinc-500",
};

const FILLED_BARS: Record<QualityReadout["label"], number> = {
  excellent: 5,
  good: 4,
  ok: 3,
  poor: 2,
  bad: 1,
  unknown: 0,
};

export function ConnectionMeter({ quality }: { quality: QualityReadout }) {
  const t = useTrWithFallback();
  const filled = FILLED_BARS[quality.label];
  const labelText = t(`call.v2.network.${quality.label}`, quality.label);

  return (
    <div
      className="flex items-center gap-1.5 rounded-full border border-subtle bg-black/60 px-2 py-1 text-[11px] font-semibold text-primary backdrop-blur"
      title={`${labelText} (${quality.uplink}↑/${quality.downlink}↓)`}
      aria-label={t("call.v2.network.aria", "Network quality") + `: ${labelText}`}
    >
      <span className="flex items-end gap-0.5" aria-hidden="true">
        {[1, 2, 3, 4, 5].map((bar) => (
          <span
            key={bar}
            className={`block w-[3px] rounded-sm ${
              bar <= filled ? COLORS[quality.label] : "bg-white/15"
            }`}
            style={{ height: `${4 + bar * 2}px` }}
          />
        ))}
      </span>
      <span className="hidden sm:inline">{labelText}</span>
    </div>
  );
}
