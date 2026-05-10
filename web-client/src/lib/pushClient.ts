import { apiUrl, authFetch, tunnelBypassHeaders } from "@/api/apiClient";

/**
 * Decodes the base64url VAPID public key from env or `GET /api/push/vapid-key`.
 */
export function urlBase64ToUint8Array(base64String: string): BufferSource {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const raw = atob(base64);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) {
    out[i] = raw.charCodeAt(i);
  }
  return out;
}

async function resolveVapidPublicKey(): Promise<string | null> {
  const fromEnv = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY?.trim();
  if (fromEnv) return fromEnv;
  try {
    const res = await fetch(apiUrl("/api/push/vapid-key"), {
      headers: tunnelBypassHeaders(),
    });
    if (!res.ok) return null;
    const j = (await res.json()) as { publicKey?: string };
    return typeof j.publicKey === "string" ? j.publicKey : null;
  } catch {
    return null;
  }
}

function pushSupported(): boolean {
  return (
    typeof window !== "undefined" &&
    "serviceWorker" in navigator &&
    "PushManager" in window &&
    "Notification" in window
  );
}

export type SubscribeToPushResult =
  | { ok: true; subscription: PushSubscription }
  | {
      ok: false;
      reason: "unsupported" | "denied" | "no_vapid" | "no_subscription" | "network";
      message?: string;
    };

/**
 * Uses the active service worker from `@ducanh2912/next-pwa` (`/sw.js`, includes
 * `worker/index.ts` push handlers). Requests permission, subscribes with VAPID,
 * and POSTs the subscription to `POST /api/notifications/subscribe`.
 */
export async function subscribeToPush(): Promise<SubscribeToPushResult> {
  if (!pushSupported()) {
    return { ok: false, reason: "unsupported", message: "Push not supported" };
  }

  let registration = await navigator.serviceWorker.getRegistration("/");
  if (!registration) {
    try {
      await navigator.serviceWorker.register("/sw.js", {
        scope: "/",
        updateViaCache: "none",
      });
    } catch (e) {
      return {
        ok: false,
        reason: "unsupported",
        message:
          e instanceof Error
            ? e.message
            : "Service worker unavailable (use a production build with PWA enabled)",
      };
    }
  }
  try {
    registration = await navigator.serviceWorker.ready;
  } catch (e) {
    return {
      ok: false,
      reason: "unsupported",
      message:
        e instanceof Error ? e.message : "Service worker did not become ready",
    };
  }
  try {
    await registration.update();
  } catch {
    /* ignore */
  }

  let permission = Notification.permission;
  if (permission === "denied") {
    return { ok: false, reason: "denied", message: "Notifications blocked" };
  }
  if (permission === "default") {
    permission = await Notification.requestPermission();
  }
  if (permission !== "granted") {
    return { ok: false, reason: "denied", message: "Permission not granted" };
  }

  const vapidKey = await resolveVapidPublicKey();
  if (!vapidKey) {
    return {
      ok: false,
      reason: "no_vapid",
      message: "Missing NEXT_PUBLIC_VAPID_PUBLIC_KEY (or server VAPID)",
    };
  }

  let subscription: PushSubscription;
  try {
    const existing = await registration.pushManager.getSubscription();
    subscription =
      existing ??
      (await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(vapidKey),
      }));
  } catch (e) {
    return {
      ok: false,
      reason: "no_subscription",
      message: e instanceof Error ? e.message : "Subscribe failed",
    };
  }

  const json = subscription.toJSON();
  try {
    const res = await authFetch(apiUrl("/api/notifications/subscribe"), {
      method: "POST",
      body: JSON.stringify({ subscription: json }),
    });
    if (!res.ok) {
      const text = await res.text();
      return {
        ok: false,
        reason: "network",
        message: text || res.statusText,
      };
    }
  } catch (e) {
    return {
      ok: false,
      reason: "network",
      message: e instanceof Error ? e.message : "Save subscription failed",
    };
  }

  return { ok: true, subscription };
}
