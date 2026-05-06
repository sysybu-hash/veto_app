/* global self */
// VETO Legal — custom push + notification click handler (scope: site root)

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

  const absoluteIcon = new URL("/icon.png", self.location.origin).href;

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon: absoluteIcon,
      badge: absoluteIcon,
      data: { url },
      tag: "veto-emergency",
      renotify: true,
      requireInteraction: true,
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
