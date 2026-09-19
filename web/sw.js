'use strict';

// Lightweight SW for PWA installability + offline + system notifications.
const CACHE = 'khutoot-baghdad-shell-v170';
const OFFLINE_URL = './offline.html';
const ICON = self.location.origin + '/icons/app-icon-192-v19.png';
const BADGE = self.location.origin + '/favicon-v19.png';

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      cache
        .addAll([
          OFFLINE_URL,
          './manifest.json',
          './favicon-v19.png',
          './icons/app-icon-192-v19.png',
          './icons/app-icon-512-v19.png',
        ])
        .catch(() => undefined),
    ),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => res)
        .catch(() =>
          caches.match(OFFLINE_URL).then(
            (cached) =>
              cached ||
              new Response('<!doctype html><meta charset=utf-8><title>دليل خطوط بغداد</title><body dir=rtl style="font-family:Tahoma,sans-serif;padding:24px;text-align:center"><h1>لا يوجد اتصال</h1><p>أعد المحاولة عند توفر الإنترنت.</p></body>', {
                headers: { 'Content-Type': 'text/html; charset=utf-8' },
              }),
          ),
        ),
    );
    return;
  }

  if (
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('manifest.json') ||
    url.pathname.endsWith('manifest-admin.json') ||
    url.pathname.endsWith('offline.html')
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

function showTrayNotification(title, body, tag) {
  const options = {
    body: body || '',
    icon: ICON,
    badge: BADGE,
    tag: tag || 'khutoot-notify',
    dir: 'rtl',
    lang: 'ar',
    renotify: true,
    requireInteraction: false,
    vibrate: [160, 80, 160],
    data: { url: self.location.origin + '/' },
  };
  return self.registration.showNotification(title || 'دليل خطوط بغداد', options);
}

self.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.type !== 'SHOW_NOTIFICATION') return;
  event.waitUntil(showTrayNotification(data.title, data.body, data.tag));
});

self.addEventListener('push', (event) => {
  let title = 'دليل خطوط بغداد';
  let body = 'لديك تحديث جديد';
  let tag = 'khutoot-push';
  try {
    if (event.data) {
      const payload = event.data.json();
      if (payload.title) title = payload.title;
      if (payload.body) body = payload.body;
      if (payload.tag) tag = payload.tag;
    }
  } catch (_) {
    try {
      const text = event.data && event.data.text();
      if (text) body = text;
    } catch (__) {}
  }
  event.waitUntil(showTrayNotification(title, body, tag));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target =
    (event.notification.data && event.notification.data.url) ||
    self.location.origin + '/';
  event.waitUntil(
    (async () => {
      const all = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      for (const client of all) {
        if ('focus' in client) {
          await client.focus();
          if ('navigate' in client) {
            try {
              await client.navigate(target);
            } catch (_) {}
          }
          return;
        }
      }
      if (self.clients.openWindow) await self.clients.openWindow(target);
    })(),
  );
});
