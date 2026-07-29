"use client";

import { useEffect, useState } from "react";
import { useTrWithFallback } from "../lib/trWithFallback";
import type { TranscriptSegment } from "../hooks/useRealtimeTranscription";

const VISIBLE_LIMIT = 3;
const FADE_AFTER_MS = 7000;

/**
 * Live captions strip — shows the most recent transcription segments at
 * the bottom of the call, like YouTube live captions. Auto-fades after
 * 7 seconds of silence and announces new finals to screen readers.
 *
 * When `translations` contains a translated string for a segment, it is
 * rendered below the original line in a subtler tone — that's the
 * Gemini-powered cross-language layer.
 */
export function CaptionsOverlay({
  enabled,
  segments,
  translations,
}: {
  enabled: boolean;
  segments: TranscriptSegment[];
  translations?: Record<string, string>;
}) {
  const t = useTrWithFallback();
  const lastTs = segments.length > 0 ? segments[segments.length - 1].ts : 0;
  const [visible, setVisible] = useState(false);

  // Sync visibility from `lastTs` — flip to visible whenever we have a
  // new segment, then schedule the fade-out without touching state during
  // render.
  useEffect(() => {
    if (!enabled) {
      queueMicrotask(() => setVisible(false));
      return undefined;
    }
    if (!lastTs) return undefined;
    queueMicrotask(() => setVisible(true));
    const remaining = FADE_AFTER_MS - (Date.now() - lastTs);
    if (remaining <= 0) {
      queueMicrotask(() => setVisible(false));
      return undefined;
    }
    const id = window.setTimeout(() => setVisible(false), remaining);
    return () => window.clearTimeout(id);
  }, [enabled, lastTs]);

  if (!enabled) return null;

  const recent = segments.slice(-VISIBLE_LIMIT);
  if (recent.length === 0) {
    return (
      <div className="pointer-events-none absolute inset-x-0 bottom-24 z-20 flex justify-center">
        <span className="rounded-full bg-black/60 px-3 py-1 text-[11px] font-semibold text-secondary backdrop-blur">
          {t("call.v2.captions.listening", "Captions on — listening…")}
        </span>
      </div>
    );
  }

  return (
    <div
      className={`pointer-events-none absolute inset-x-0 bottom-24 z-20 flex justify-center transition-opacity duration-500 ${
        visible ? "opacity-100" : "opacity-0"
      }`}
      aria-live="polite"
      aria-atomic="false"
    >
      <div className="max-w-3xl space-y-1 rounded-2xl bg-black/70 px-4 py-2 text-center text-sm leading-6 text-inverse backdrop-blur">
        {recent.map((seg) => {
          const translated = translations?.[seg.segmentId];
          return (
            <div key={seg.segmentId} className="space-y-0.5">
              <p
                className={
                  seg.isFinal ? "text-white" : "text-secondary italic"
                }
              >
                {seg.speaker && (
                  <span className="me-1 text-[11px] text-amber-300">
                    {seg.speaker}:
                  </span>
                )}
                {seg.text}
              </p>
              {translated && (
                <p
                  className="text-[12px] leading-5 text-emerald-200/90"
                  lang="auto"
                >
                  {translated}
                </p>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
