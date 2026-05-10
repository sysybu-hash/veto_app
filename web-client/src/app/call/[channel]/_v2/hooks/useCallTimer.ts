"use client";

import { useEffect, useState } from "react";

/**
 * Tiny stopwatch hook — emits a fresh seconds value every 1s starting from
 * `startedAt` (epoch ms). Designed for the call header timer.
 */
export function useCallTimer(startedAt: number) {
  const [elapsedSec, setElapsedSec] = useState(() =>
    Math.floor((Date.now() - startedAt) / 1000),
  );

  useEffect(() => {
    const id = window.setInterval(() => {
      setElapsedSec(Math.floor((Date.now() - startedAt) / 1000));
    }, 1000);
    return () => window.clearInterval(id);
  }, [startedAt]);

  return {
    elapsedSec,
    label: formatHHMMSS(elapsedSec),
  };
}

export function formatHHMMSS(totalSeconds: number) {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  const pad = (n: number) => String(n).padStart(2, "0");
  return h > 0 ? `${pad(h)}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`;
}
