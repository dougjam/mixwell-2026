// @ts-check
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';

// ---------------------------------------------------------------------------
// Deployment configuration
// ---------------------------------------------------------------------------
// This site defaults to a GitHub *project page* served under a base path:
//
//     https://<user>.github.io/mixwell-2026/
//
// To switch to a CUSTOM DOMAIN (e.g. https://mixwell.example.org/):
//   1. Set   site: 'https://mixwell.example.org'   and   base: '/'   below.
//   2. Add a `public/CNAME` file containing just the bare domain
//      (e.g. `mixwell.example.org`) so GitHub Pages serves it.
//
// Every internal link and asset in the site is routed through the `withBase()`
// helper in `src/lib/paths.ts`, so changing `base` here is all that is needed —
// no template edits.
// ---------------------------------------------------------------------------

const SITE = 'https://dougjam.github.io';
const BASE = '/mixwell-2026';

export default defineConfig({
  site: SITE,
  base: BASE,
  trailingSlash: 'ignore',
  integrations: [mdx()],
  markdown: {
    // Math is rendered via the build-time <Math /> component (KaTeX), so no
    // markdown math plugins are needed here.
    shikiConfig: {
      theme: 'github-dark',
      wrap: false,
    },
  },
});
