/* global self */
// VETO Legal — PWA shell cache + push + notification click handler (scope: site root)

const CACHE_NAME = "veto-pwa-v3";
const APP_SHELL = [
  "/offline.html",
  "/manifest.webmanifest",
  "/veto-logo.svg?v=20260210",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
  "/icons/maskable-192.png",
  "/icons/maskable-512.png",
  "/icons/apple-touch-icon.png",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request).catch(() => caches.match("/offline.html")),
    );
    return;
  }

  if (
    url.pathname.startsWith("/icons/") ||
    url.pathname === "/manifest.webmanifest" ||
    url.pathname === "/offline.html" ||
    url.pathname === "/veto-logo.svg"
  ) {
    event.respondWith(
      caches.match(request).then((cached) => cached || fetch(request)),
    );
  }
});

self.addEventListener("push", (event) => {
  let title = "VETO Legal";
  let body = "You have a new notification.";
  /** @type {string} */
  let url = "/dashboard";

  if (event.data) {
    try {
      const parsed = event.data.json();
      if (typeof parsed.title === "string" && parsed.title) title = parsed.title;
      if (typeof parsed.body === "string" && parsed.body) body = parsed.body;
      if (typeof parsed.url === "string" && parsed.url) url = parsed.url;
      else if (
        parsed.data &&
        typeof parsed.data === "object" &&
        typeof parsed.data.url === "string" &&
        parsed.data.url
      ) {
        url = parsed.data.url;
      }
    } catch {
      try {
        const t = event.data.text();
        if (t) body = t;
      } catch {
        /* ignore */
      }
    }
  }

  const absoluteIcon = new URL("/icons/icon-192.png", self.location.origin).href;

  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      const hasActiveCall = clientList.some((client) => {
        try {
          return new URL(client.url).pathname.startsWith("/call/");
        } catch {
          return false;
        }
      });
      if (hasActiveCall) return undefined;
      return self.registration.showNotification(title, {
        body,
        icon: absoluteIcon,
        badge: absoluteIcon,
        data: { url },
        tag: "veto-emergency",
        renotify: true,
        requireInteraction: true,
      });
    }),
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const raw =
    event.notification.data && typeof event.notification.data.url === "string"
      ? event.notification.data.url
      : "/dashboard";
  let targetUrl;
  try {
    targetUrl = new URL(raw, self.location.origin).href;
  } catch {
    targetUrl = new URL("/dashboard", self.location.origin).href;
  }

  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url === targetUrl && "focus" in client) {
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
      return undefined;
    }),
  );
});
