const CACHE_NAME = 'mi-curso-shell-v1';
const SHELL_URLS = [
  './mi-curso.html',
  './supabase-config.js',
  './manifest.webmanifest',
  './icons/mi-curso-192.png',
  './icons/mi-curso-512.png'
];
const SHELL_PATHS = new Set(
  SHELL_URLS.map(path => new URL(path, self.registration.scope).pathname)
);

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(SHELL_URLS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(names => Promise.all(
        names.filter(name => name.startsWith('mi-curso-shell-') && name !== CACHE_NAME)
          .map(name => caches.delete(name))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;

  const isAppNavigation = request.mode === 'navigate' &&
    url.pathname === new URL('./mi-curso.html', self.registration.scope).pathname;
  if (!isAppNavigation && !SHELL_PATHS.has(url.pathname)) return;

  event.respondWith((async () => {
    try {
      const response = await fetch(request);
      if (response.ok) {
        event.waitUntil(
          caches.open(CACHE_NAME)
            .then(cache => cache.put(request, response.clone()))
            .catch(error => console.error('No se pudo actualizar la caché de la app', error))
        );
      }
      return response;
    } catch (error) {
      const cached = await caches.match(request);
      if (cached) return cached;
      throw error;
    }
  })());
});
