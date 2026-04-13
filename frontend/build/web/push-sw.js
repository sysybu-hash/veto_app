// ============================================================
//  push-sw.js — VETO Push Notification Service Worker
//  Handles incoming push events and shows system notifications
//  even when the app tab is closed.
// ============================================================

self.addEventListener('push', function (event) {
  let data = {};
  try { data = event.data.json(); } catch (_) {}

  const title   = data.title || '🚨 VETO Emergency';
  const body    = data.body  || 'A client needs legal help urgently.';
  const payload = data.data  || {};

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon:  '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data:  payload,
      tag:   'veto-emergency',   // replaces previous notification (no spam)
      renotify: true,
      requireInteraction: true,  // stays visible until dismissed
      actions: [
        { action: 'open',   title: '✅ Respond' },
        { action: 'dismiss', title: '✕ Dismiss' },
      ],
    }),
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  if (event.action === 'dismiss') return;

  // Open (or focus) the app window
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (windowClients) {
      for (const client of windowClients) {
        if ('focus' in client) return client.focus();
      }
      return clients.openWindow('/');
    }),
  );
});
