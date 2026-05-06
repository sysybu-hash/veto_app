import Ably from "ably";
import type { ClientOptions } from "ably";

/** Lawyer dashboards subscribe; server publishes citizen SOS here. */
export const SOS_ALERTS_CHANNEL = "sos-alerts";

/** Message name on the channel (subscribable with .subscribe(eventName, ...)). */
export const SOS_EVENT_NAME = "sos-alert";

/** Broadcast when a lawyer claims an SOS row (all subscribers refresh local queue). */
export const SOS_CLAIMED_EVENT_NAME = "sos-claimed";

let restSingleton: Ably.Rest | null = null;

export function isAblyConfigured(): boolean {
  return Boolean(process.env.ABLY_API_KEY?.trim());
}

/**
 * Server-side REST client for publishing (uses full API key — never import in client bundles).
 */
export function getAblyRest(): Ably.Rest {
  const key = process.env.ABLY_API_KEY;
  if (!key?.trim()) {
    throw new Error("ABLY_API_KEY is not set");
  }
  if (!restSingleton) {
    restSingleton = new Ably.Rest(key);
  }
  return restSingleton;
}

/**
 * Browser Realtime client with token auth callback (do not pass API key in the browser).
 */
export function createAblyRealtimeWithAuth(
  authCallback: NonNullable<ClientOptions["authCallback"]>,
): Ably.Realtime {
  return new Ably.Realtime({ authCallback, closeOnUnload: true });
}
