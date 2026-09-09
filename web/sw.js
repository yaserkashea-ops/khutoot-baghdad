'use strict';

// Bump this with every deploy so old tabs/apps reload onto the new build.
const APP_VERSION = 'v14';
const CACHE = 'khutoot-baghdad-' + APP_VERSION;

self.addEventListener('install', (event) => {
  // Activate immediately; do not wait for old tabs to close.
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE).then(() => undefined));
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  // Navigations and shell files: always hit the network (ignore HTTP cache).
  const url = new URL(req.url);
  const isShell =
    req.mode === 'navigate' ||
    url.pathname === '/' ||
    url.pathname.endsWith('/index.html') ||
    url.pathname.endsWith('/admin.html') ||
    url.pathname.endsWith('/sw.js') ||
    url.pathname.endsWith('/flutter_bootstrap.js') ||
    url.pathname.endsWith('/version.json');

  if (isShell && url.origin === self.location.origin) {
    event.respondWith(
      fetch(req, { cache: 'no-store' }).catch(() =>
        caches.match(req).then((cached) => {
          if (cached) return cached;
          return caches.match('./index.html').then((h) => h || caches.match('./admin.html'));
        }),
      ),
    );
    return;
  }

  event.respondWith(
    fetch(req)
      .then((res) => {
        try {
          if (url.origin === self.location.origin) {
            const path = url.pathname;
            const cacheable =
              path.endsWith('.png') ||
              path.endsWith('favicon.png');
            if (cacheable && res.ok) {
              const copy = res.clone();
              caches.open(CACHE).then((cache) => cache.put(req, copy)).catch(() => {});
            }
          }
        } catch (_) {}
        return res;
      })
      .catch(() => caches.match(req)),
  );
});
