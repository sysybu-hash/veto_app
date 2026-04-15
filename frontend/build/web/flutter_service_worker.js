// Killer Service Worker
// This replaces the old flutter_service_worker.js and forces it to self-destruct.

self.addEventListener('install', (e) => {
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          console.log('[ServiceWorker] Deleting old cache:', cacheName);
          return caches.delete(cacheName);
        })
      );
    }).then(() => {
      console.log('[ServiceWorker] Unregistering self...');
      return self.registration.unregister();
    }).then(() => {
      console.log('[ServiceWorker] Claiming clients and reloading...');
      return self.clients.claim();
    }).then(() => {
      return self.clients.matchAll({ type: 'window' }).then((clients) => {
        clients.forEach((client) => {
          client.navigate(client.url);
        });
      });
    })
  );
});

self.addEventListener('fetch', (e) => {
  // Do nothing, let the network handle it
});