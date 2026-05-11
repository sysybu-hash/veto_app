"use client";

import { useTrWithFallback } from "../lib/trWithFallback";

type ConnectionStatus =
  | "DISCONNECTED"
  | "CONNECTING"
  | "RECONNECTING"
  | "CONNECTED"
  | "DISCONNECTING"
  | "FAILED";

/**
 * Full-screen overlay shown while the Agora client is mid-reconnect.
 * Non-blocking — clicks fall through to the call surface so the user
 * can still hit "End call" if they give up.
 */
export function ReconnectingOverlay({ state }: { state: ConnectionStatus }) {
  const t = useTrWithFallback();
  if (state !== "RECONNECTING" && state !== "CONNECTING" && state !== "FAILED") {
    return null;
  }
  const isFailed = state === "FAILED";

  return (
    <div
      className="pointer-events-none absolute inset-0 z-40 flex items-center justify-center bg-black/40 backdrop-blur-[2px]"
      role="status"
      aria-live="polite"
    >
      <div
        className={`flex items-center gap-3 rounded-full border px-4 py-2 text-sm font-semibold backdrop-blur ${
          isFailed
            ? "border-red-500/50 bg-red-950/80 text-red-100"
            : "border-amber-400/40 bg-amber-950/80 text-amber-100"
        }`}
      >
        {!isFailed && (
          <span
            aria-hidden="true"
            className="inline-block size-3 animate-pulse rounded-full bg-amber-300"
          />
        )}
        <span>
          {isFailed
            ? t("call.v2.reconnect.failed", "Connection lost")
            : t("call.v2.reconnect.busy", "Reconnecting…")}
        </span>
      </div>
    </div>
  );
}
