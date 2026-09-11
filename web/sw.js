'use strict';

// Installability-only SW. Does not cache app JS/HTML so stable URLs get updates.
const CACHE = 'khutoot-baghdad-shell-v28';

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      cache
        .addAll(['./manifest.json', './favicon-v18.png', './icons/app-icon-192-v18.png'])
        .catch(() => undefined),
    ),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      // Drop previous shells and Flutter's deprecated SW caches.
      await Promise.all(
        keys
          .filter((k) => k !== CACHE)
          .map((k) => caches.delete(k)),
      );
      await self.clients.claim();
    })(),
  );
});

// Never intercept navigations or JS — browsers always fetch fresh app code.
self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  // Offline fallback for icons/manifest only.
  if (
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('manifest.json') ||
    url.pathname.endsWith('manifest-admin.json')
  ) {
    event.respondWith(
      fetch(req, { cache: 'no-store' })
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((cache) => cache.put(req, copy)).catch(() => undefined);
          return res;
        })
        .catch(() => caches.match(req)),
    );
  }
});
