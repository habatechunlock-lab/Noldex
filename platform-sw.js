const CACHE_NAME = 'noldex-platform-v1';
const ASSETS = [
  './platform.html',
  './favicon.svg',
  './favicon-32x32.png',
  './apple-touch-icon.png',
  './icon-192.png',
  './icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  // Réseau d'abord pour la plateforme (données live : GPS, contrats...), cache en secours
  event.respondWith(
    fetch(event.request).then((resp) => {
      const respClone = resp.clone();
      caches.open(CACHE_NAME).then((cache) => cache.put(event.request, respClone)).catch(() => {});
      return resp;
    }).catch(() => caches.match(event.request))
  );
});
