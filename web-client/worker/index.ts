/// <reference lib="webworker" />

self.addEventListener("push", (event) => {
  let data: { title?: string; body?: string; url?: string } = {};
  try {
    data = event.data?.json() ?? {};
  } catch {
    try {
      const text = event.data?.text();
      if (text) data = JSON.parse(text) as typeof data;
    } catch {
      /* ignore */
    }
  }
  const title = data?.title || "קריאת חירום - VETO";
  const options: NotificationOptions = {
    body:
      data?.body ||
      "עורך דין, ישנה קריאת SOS חדשה שממתינה למענה מיידי.",
    icon: "/icons/icon-192.png",
    badge: "/icons/icon-192.png",
    data: {
      url: data?.url || "/",
    },
    tag: "sos-notification",
    renotify: true,
    requireInteraction: true,
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const url =
    typeof event.notification.data === "object" &&
    event.notification.data !== null &&
    typeof (event.notification.data as { url?: unknown }).url === "string"
      ? (event.notification.data as { url: string }).url
      : "/";
  event.waitUntil(self.clients.openWindow(url));
});
