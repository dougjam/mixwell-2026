/*
 * Cross-origin isolation service worker.
 *
 * The Mixwell WebGPU demo is built with pthreads, so it needs SharedArrayBuffer,
 * which browsers only expose when the page is "cross-origin isolated"
 * (Cross-Origin-Opener-Policy: same-origin + Cross-Origin-Embedder-Policy:
 * require-corp). Static hosts such as GitHub Pages cannot set response headers,
 * so this service worker re-serves same-scope responses with those headers added.
 *
 * Approach popularized by github.com/gzuidhof/coi-serviceworker (MIT).
 */

if (typeof window === 'undefined') {
  // ---- Service worker context -------------------------------------------
  self.addEventListener('install', () => self.skipWaiting());
  self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

  self.addEventListener('fetch', (event) => {
    const request = event.request;
    // Skip range/cache-only cross-origin requests that must stay untouched.
    if (request.cache === 'only-if-cached' && request.mode !== 'same-origin') return;

    event.respondWith(
      fetch(request)
        .then((response) => {
          // Opaque responses (status 0) cannot be rewritten; pass through.
          if (response.status === 0) return response;

          const headers = new Headers(response.headers);
          headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
          headers.set('Cross-Origin-Opener-Policy', 'same-origin');
          headers.set('Cross-Origin-Resource-Policy', 'cross-origin');

          return new Response(response.body, {
            status: response.status,
            statusText: response.statusText,
            headers,
          });
        })
        .catch((err) => {
          console.error('[coi] fetch failed:', err);
          return Response.error();
        })
    );
  });
} else {
  // ---- Page context -----------------------------------------------------
  (() => {
    // Already isolated → nothing to do (also prevents a reload loop).
    if (window.crossOriginIsolated) return;

    if (!window.isSecureContext) {
      console.warn('[coi] Not a secure context; cross-origin isolation unavailable.');
      return;
    }
    if (!('serviceWorker' in navigator)) {
      console.warn('[coi] Service workers unsupported; cross-origin isolation unavailable.');
      return;
    }

    const swUrl = document.currentScript && document.currentScript.src;
    if (!swUrl) return;

    navigator.serviceWorker
      .register(swUrl)
      .then((registration) => {
        // When the worker takes control for the first time, reload so the page
        // is served through it (and thus becomes cross-origin isolated).
        registration.addEventListener('updatefound', () => window.location.reload());
        if (registration.active && !navigator.serviceWorker.controller) {
          window.location.reload();
        }
      })
      .catch((err) => console.error('[coi] Service worker registration failed:', err));
  })();
}
