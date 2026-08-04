/// <reference lib="webworker" />

declare const self: ServiceWorkerGlobalScope;

type PushPayload = {
  title?: string;
  body?: string;
  url?: string;
  eventId?: string;
  userId?: string;
  userName?: string;
  language?: string;
  timestamp?: string;
  location?: { lat?: number | string; lng?: number | string };
  data?: Record<string, unknown>;
};

function buildLawyerSosUrl(data: PushPayload): string {
  const nested = data.data && typeof data.data === "object" ? data.data : null;
  const eventId =
    (typeof data.eventId === "string" && data.eventId) ||
    (nested && typeof nested.eventId === "string" ? nested.eventId : "") ||
    "";

  // Prefer a deep-link with eventId over a bare /dashboard URL from older payloads.
  const rawUrl = typeof data.url === "string" ? data.url.trim() : "";
  if (rawUrl && eventId) {
    try {
      const u = new URL(rawUrl, "https://veto.local");
      if (u.pathname === "/dashboard" && !u.searchParams.get("eventId")) {
        // fall through and rebuild
      } else if (u.searchParams.get("eventId") || u.pathname !== "/dashboard") {
        return rawUrl;
      }
    } catch {
      if (rawUrl.includes("eventId=")) return rawUrl;
    }
  } else if (rawUrl && !eventId) {
    return rawUrl;
  }

  if (!eventId) return "/dashboard";

  const params = new URLSearchParams({ tab: "calls", eventId });
  const userId = data.userId ?? nested?.userId;
  const userName = data.userName ?? nested?.userName;
  const language = data.language ?? nested?.language;
  const timestamp = data.timestamp ?? nested?.timestamp;
  const loc =
    data.location ||
    (nested?.location && typeof nested.location === "object"
      ? (nested.location as { lat?: number | string; lng?: number | string })
      : undefined);

  if (userId != null) params.set("userId", String(userId));
  if (typeof userName === "string" && userName) params.set("userName", userName);
  if (typeof language === "string" && language) params.set("language", language);
  if (typeof timestamp === "string" && timestamp) params.set("ts", timestamp);
  if (loc) {
    const lat = Number(loc.lat);
    const lng = Number(loc.lng);
    if (Number.isFinite(lat)) params.set("lat", String(lat));
    if (Number.isFinite(lng)) params.set("lng", String(lng));
  }
  return `/dashboard?${params.toString()}`;
}

self.addEventListener("push", (event) => {
  let data: PushPayload = {};
  try {
    data = (event.data?.json() ?? {}) as PushPayload;
  } catch {
    try {
      const text = event.data?.text();
      if (text) data = JSON.parse(text) as PushPayload;
    } catch {
      /* ignore */
    }
  }

  const url = buildLawyerSosUrl(data);
  const title = data?.title || "קריאת חירום - VETO";
  const options: NotificationOptions = {
    body:
      data?.body ||
      "עורך דין, ישנה קריאת SOS חדשה שממתינה למענה מיידי.",
    icon: "/icons/icon-192.png",
    badge: "/icons/icon-192.png",
    data: {
      ...data,
      url,
    },
    tag: data.eventId ? `sos-${data.eventId}` : "sos-notification",
    renotify: true,
    requireInteraction: true,
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const raw = event.notification.data;
  const data =
    raw && typeof raw === "object" ? (raw as PushPayload & { url?: string }) : {};
  const targetPath = buildLawyerSosUrl(data);
  const targetUrl = new URL(targetPath, self.location.origin).href;

  event.waitUntil(
    (async () => {
      const clientsArr = await self.clients.matchAll({
        type: "window",
        includeUncontrolled: true,
      });
      for (const client of clientsArr) {
        if ("focus" in client) {
          await client.focus();
          if ("navigate" in client) {
            try {
              await (client as WindowClient).navigate(targetUrl);
              return;
            } catch {
              /* fall through to openWindow */
            }
          }
        }
      }
      await self.clients.openWindow(targetUrl);
    })(),
  );
});
