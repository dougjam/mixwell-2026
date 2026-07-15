// Base-path helper.
//
// Every internal link and asset reference in the site must go through withBase()
// so that the configured Astro `base` (e.g. "/mixwell-2026") is applied
// consistently. This is the single most common source of broken links on GitHub
// project pages, so do NOT hand-write raw "/..." URLs in templates.

const BASE_URL = import.meta.env.BASE_URL; // e.g. "/mixwell-2026/" or "/"

/**
 * Join a site-relative path to the configured base URL.
 *
 *   withBase("/code")                  -> "/mixwell-2026/code"
 *   withBase("placeholders/hero.svg")  -> "/mixwell-2026/placeholders/hero.svg"
 *
 * Absolute URLs (http(s):, mailto:, protocol-relative //) are returned as-is.
 */
export function withBase(path: string): string {
  if (!path) return BASE_URL;
  if (/^([a-z]+:)?\/\//i.test(path) || path.startsWith('mailto:')) {
    return path;
  }
  const base = BASE_URL.endsWith('/') ? BASE_URL.slice(0, -1) : BASE_URL;
  const rel = path.startsWith('/') ? path : `/${path}`;
  return `${base}${rel}`;
}

/** True for external/absolute links (used to decide target/rel attributes). */
export function isExternal(url: string | null | undefined): boolean {
  if (!url) return false;
  return /^([a-z]+:)?\/\//i.test(url) || url.startsWith('mailto:');
}
