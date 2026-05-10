"use client";

import { useCallback } from "react";
import { subscribeToPush } from "@/lib/pushClient";

/**
 * Web Push (VAPID) for lawyers — uses `NEXT_PUBLIC_VAPID_PUBLIC_KEY` or
 * `GET /api/push/vapid-key`, the active `/sw.js` (next-pwa + `worker/index.ts`),
 * and `POST /api/notifications/subscribe` with `{ subscription }` (see `pushClient`).
 */
export function useWebPush() {
  const subscribe = useCallback(async () => {
    const result = await subscribeToPush();
    if (result.ok) {
      console.log("✅ Web Push Subscribed successfully");
    } else {
      console.error(
        "❌ Web Push Subscription failed:",
        result.reason,
        result.message ?? "",
      );
    }
    return result;
  }, []);

  return { subscribe };
}
