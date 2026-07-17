# Mixwell project website

Static project page for *Mixwell: Sharp 2D Fluid Brushes for Progressive
Physics-Based Mixing* (ACM Transactions on Graphics 45(4), Article 79). Built
with [Astro](https://astro.build) and deployed to GitHub Pages.

## Requirements

- Node.js (see [`.nvmrc`](.nvmrc) for the version)

## Run locally

```bash
npm install      # install dependencies
npm run dev      # start the dev server (http://localhost:4321/mixwell-2026/)
npm run build    # build the static site into dist/
npm run preview  # preview the built site
```

## Editing content

All content is data-driven — add items by editing data files, never layout.

| What | Where |
| --- | --- |
| Paper metadata, authors, abstract, badges, primary links, BibTeX, news | [`src/data/site.config.yaml`](src/data/site.config.yaml) |
| Interactive demo cards | [`src/data/demos.yaml`](src/data/demos.yaml) |
| Shadertoy gallery entries | [`src/data/shaders.yaml`](src/data/shaders.yaml) |
| Code libraries (`/code` page) | [`src/data/libraries.yaml`](src/data/libraries.yaml) |
| Gallery images | [`src/data/gallery.yaml`](src/data/gallery.yaml) |
| Explainer articles | Add an `.mdx` file under [`src/content/explainers/`](src/content/explainers/) |

Fields marked `TODO:` in the data files are placeholders — fill them in as the
real values become available (paper PDF URL, YouTube IDs, dataset links,
thumbnails, explainer prose). **Do not invent citation, DOI, or BibTeX values.**

### Explainer articles

Copy `src/content/explainers/reverse-drift-functions-intro.mdx` as a starting
point. Front matter fields: `title`, `blurb`, `thumbnail`, `order`, and optional
`draft: true`. Articles support KaTeX math via the `<Math />` component
(`<Math tex="a^2 + b^2" />` inline, `<Math display tex={String.raw`\frac{a}{b}`} />`
for a centered block), copyable code blocks, the `<ShaderCanvas />` live shader
component, and the `<SampleScrubber />` frame comparator.

### Images

Keep committed images **web-optimized** (WebP/AVIF or optimized PNG/JPEG), sized
for display, not masters. Do not commit video files — use a YouTube embed by
setting the relevant video ID in `site.config.yaml`. Put large datasets and
full-resolution masters behind a Google Drive or Dropbox link in the config, not
in the repository.

The neutral placeholder images live in [`public/placeholders/`](public/placeholders/);
swap them for real assets as they become available.

#### Teaser hero

The landing hero is `public/teaser/hero.webp` (set via `teaser.image` in the
config). To swap it, drop in a new web-optimized still and update `teaser.image`,
or set `teaser.teaserVideoId` to a YouTube ID to show a looping clip instead.

A helper for downscaling a source image to a web-suitable teaser lives at
`scripts/make-teaser.py` (run locally with Python + Pillow; it is not part of the
build). If you have `sharp` handy (already a dependency), a one-liner also works:

```bash
node -e "require('sharp')('input.jpg').webp({quality:82}).toFile('public/teaser/hero.webp')"
```

### Currently hidden sections

**Explainers** and **Gallery** are intentionally hidden for now (no content yet).
Their pages and data still build — they're just unlinked from the site. To bring
one back:

- **Nav link:** re-add its entry to the `nav` array in
  [`src/layouts/Base.astro`](src/layouts/Base.astro).
- **Landing page:** un-comment its block in
  [`src/pages/index.astro`](src/pages/index.astro) (search for the marker comment,
  e.g. `Gallery preview hidden` or `Explainers hidden`).

Everything to re-enable them is already in place — just add content
(`gallery.yaml` images, or an `.mdx` explainer) and restore the two links above.

## Interactive WebGPU demo

The built demo is bundled under `public/demos/webgpu/app/` and runs as a
standalone, full-screen page. The `/demos/webgpu` page detects WebGPU support and
shows a **Launch the demo** button (or a recorded-video fallback via
`links.supplementalVideoId` when WebGPU is unavailable).

**Cross-origin isolation.** The demo uses multithreading (SharedArrayBuffer), so
its page must be *cross-origin isolated*. GitHub Pages can't set the required
`COOP`/`COEP` headers, so `app/coi-serviceworker.js` adds them via a service
worker and `app/index.html` waits for isolation before loading `Mixwell.html`.
This is why the demo launches as its own page rather than in an iframe (a framed
page would force those headers onto the whole site). Those two wrapper files are
site-maintained — don't overwrite them when refreshing the demo.

**Refreshing the demo build.** Copy the five runtime files (`Mixwell.html`,
`Mixwell.js`, `Mixwell.wasm`, `Mixwell.data`, `Mixwell.worker.js`) from the
Emscripten build output into `public/demos/webgpu/app/`. On Windows you can use
the helper script (pass `-BuildDir` if your build path differs):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-webgpu-demo.ps1
```

See [`public/demos/webgpu/README.md`](public/demos/webgpu/README.md) for details.

> `Mixwell.wasm` is ~8 MB. That's committed to the repo so the demo is
> self-contained; it's well under GitHub's limits but is the largest asset here.

## Deployment

Pushing to `main` triggers [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml),
which builds the site and publishes it to GitHub Pages. In the repository
settings, set **Pages → Build and deployment → Source** to **GitHub Actions**.

### Project page vs. custom domain

The site defaults to a GitHub **project page** served under a base path
(`/mixwell-2026`). To change deployment, edit `site` and `base` in
[`astro.config.mjs`](astro.config.mjs):

- **Project page** (default): `site: 'https://<user>.github.io'`, `base: '/mixwell-2026'`.
- **Custom domain**: `site: 'https://your-domain'`, `base: '/'`, and add a
  `public/CNAME` file containing just the bare domain (e.g. `mixwell.example.org`).

Every internal link and asset is routed through the `withBase()` helper in
`src/lib/paths.ts`, so changing `base` is all that is required.

## Maintainers

- Add the co-author as a repository collaborator for shared push access
  (**Settings → Collaborators**).
- Add new demos, shaders, libraries, gallery items, and news entries by editing
  the corresponding data file; add explainers by adding an MDX file.
- Keep committed images web-optimized; put anything large behind a Google Drive
  or Dropbox link in the config.
