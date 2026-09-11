'use strict';

// Minimal SW for PWA installability only — never force page reloads.
const CACHE = 'khutoot-baghdad-shell-v27';

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      cache
        .addAll([
          './manifest.json',
          './favicon-v18.png',
          './icons/app-icon-192-v18.png',
        ])
        .catch(() => undefined),
    ),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
      await self.clients.claim();
    })(),
  );
});

// Network-first for icons/manifest so icon updates are not stuck offline-cache.
self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  if (
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('manifest.json') ||
    url.pathname.endsWith('manifest-admin.json')
  ) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((cache) => cache.put(req, copy)).catch(() => undefined);
          return res;
        })
        .catch(() => caches.match(req)),
    );
  }
});
