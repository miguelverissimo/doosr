const CACHE_VERSION = 'v3';
const CACHE_NAME = `doosr-${CACHE_VERSION}`;

// Assets to cache on install
const PRECACHE_URLS = [
  '/',
  '/web-app-manifest-192x192.png',
  '/web-app-manifest-512x512.png',
  '/icon.svg'
];

// Install event - precache essential assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name.startsWith('doosr-') && name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - Network First strategy with cache fallback
self.addEventListener('fetch', (event) => {
  // Skip cross-origin requests
  if (!event.request.url.startsWith(self.location.origin)) {
    return;
  }

  // Skip non-GET requests
  if (event.request.method !== 'GET') {
    return;
  }

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Cache successful responses
        if (response.status === 200) {
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }
        return response;
      })
      .catch(() => {
        // Network failed, try cache
        return caches.match(event.request).then((cachedResponse) => {
          if (cachedResponse) {
            return cachedResponse;
          }
          // Return a custom offline page if you have one
          // return caches.match('/offline.html');
        });
      })
  );
});

// Web Push notifications support
self.addEventListener("push", async (event) => {
  console.log('[Service Worker] Push event received', event);

  if (event.data) {
    try {
      const data = await event.data.json();
      console.log('[Service Worker] Push data:', data);

      const { title, options } = data;
      console.log('[Service Worker] Showing notification:', title, options);

      const showPromise = self.registration.showNotification(title, options)
        .then(() => {
          console.log('[Service Worker] Notification shown successfully!');
        })
        .catch((error) => {
          console.error('[Service Worker] showNotification failed:', error);
        });

      event.waitUntil(showPromise);
    } catch (error) {
      console.error('[Service Worker] Error parsing push data:', error);
      console.log('[Service Worker] Raw push data:', event.data.text());
    }
  } else {
    console.warn('[Service Worker] Push event has no data');
  }
});

self.addEventListener("notificationclick", function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      for (let i = 0; i < clientList.length; i++) {
        let client = clientList[i];
        let clientPath = (new URL(client.url)).pathname;

        if (clientPath == event.notification.data.path && "focus" in client) {
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(event.notification.data.path);
      }
    })
  );
});
