"use client";

import type { NetworkQuality } from "agora-rtc-sdk-ng";

export type QualityLevel = 0 | 1 | 2 | 3 | 4 | 5 | 6;

export type QualityReadout = {
  uplink: QualityLevel;
  downlink: QualityLevel;
  worst: QualityLevel;
  /** Human-readable label, used by the meter UI. */
  label: "excellent" | "good" | "ok" | "poor" | "bad" | "unknown";
};

export function summariseQuality(q: NetworkQuality | null): QualityReadout {
  if (!q) {
    return { uplink: 0, downlink: 0, worst: 0, label: "unknown" };
  }
  const uplink = q.uplinkNetworkQuality as QualityLevel;
  const downlink = q.downlinkNetworkQuality as QualityLevel;
  const worst = Math.max(uplink, downlink) as QualityLevel;
  // Agora levels: 0=unknown, 1=excellent, 2=good, 3=poor, 4=bad, 5=very bad, 6=disconnected.
  let label: QualityReadout["label"] = "unknown";
  if (worst === 1) label = "excellent";
  else if (worst === 2) label = "good";
  else if (worst === 3) label = "ok";
  else if (worst === 4) label = "poor";
  else if (worst >= 5) label = "bad";
  return { uplink, downlink, worst, label };
}
