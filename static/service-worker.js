/* ============================================================
   CERITA DORANG — Service Worker
   PWA: cache assets + offline fallback
   ============================================================ */

var CACHE_VERSION = 'dorang-v1';
var STATIC_CACHE = CACHE_VERSION + '-static';
var PAGES_CACHE = CACHE_VERSION + '-pages';

/* Halaman core yang langsung dicache saat install */
var CORE_PAGES = [
  '/',
  '/privasi/',
  '/tentang-situs/',
  '/kontak/',
  '/arsip/',
  '/404.html'
];

/* Install — precache core */
self.addEventListener('install', function (event) {
  event.waitUntil(
    caches.open(PAGES_CACHE).then(function (cache) {
      return cache.addAll(CORE_PAGES).catch(function (err) {
        console.warn('SW: gagal precache beberapa halaman', err);
      });
    })
  );
  self.skipWaiting();
});

/* Activate — cleanup cache lama */
self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.filter(function (k) {
          return k.indexOf('dorang-') === 0 && k.indexOf(CACHE_VERSION) === -1;
        }).map(function (k) {
          return caches.delete(k);
        })
      );
    })
  );
  self.clients.claim();
});

/* Fetch — strategi per jenis request */
self.addEventListener('fetch', function (event) {
  var request = event.request;

  /* Hanya cache GET */
  if (request.method !== 'GET') return;

  /* Skip cross-origin (kecuali CDN jsdelivr untuk Fuse.js) */
  var url = new URL(request.url);
  if (url.origin !== location.origin && url.hostname !== 'cdn.jsdelivr.net') {
    return;
  }

  /* HTML navigation → network first, fallback cache */
  if (request.mode === 'navigate' || request.destination === 'document') {
    event.respondWith(
      fetch(request).then(function (response) {
        var copy = response.clone();
        caches.open(PAGES_CACHE).then(function (cache) {
          cache.put(request, copy);
        });
        return response;
      }).catch(function () {
        return caches.match(request).then(function (cached) {
          return cached || caches.match('/');
        });
      })
    );
    return;
  }

  /* Asset (CSS/JS/img/font) → cache first, fallback network */
  event.respondWith(
    caches.match(request).then(function (cached) {
      if (cached) return cached;
      return fetch(request).then(function (response) {
        if (!response || response.status !== 200 || response.type === 'error') {
          return response;
        }
        var copy = response.clone();
        caches.open(STATIC_CACHE).then(function (cache) {
          cache.put(request, copy);
        });
        return response;
      }).catch(function () {
        return new Response('', { status: 404, statusText: 'Offline' });
      });
    })
  );
});
