# Maintaining the website

Instructions for building, editing, and deploying the Mixwell project website.
For what this repository is and where the released code lives, see
[`README.md`](README.md).

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

Any primary link left `null` in the config renders as a disabled "soon" control.
**Never invent citation, DOI, or BibTeX values** — the values in
`site.config.yaml` are authoritative and must match the published record.

Released source files under `public/code/` are read at build time, so editing
one (locally or on GitHub) updates both the download and its highlighted page on
the next deploy. Give any new source file the standard two-line header, so the
license travels with the file if someone copies it out of the repo:

```
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Doug L. James and Ethan James
```

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
full-resolution masters behind an external link in the config, not in the
repository.

#### Teaser hero

The landing hero is `public/teaser/hero.webp` (set via `teaser.image` in the
config). To swap it, drop in a new web-optimized still and update `teaser.image`,
or set `teaser.teaserVideoId` to a YouTube ID to show a looping clip instead.
With `sharp` (already a dependency), a one-liner converts a new source:

```bash
node -e "require('sharp')('input.jpg').webp({quality:82}).toFile('public/teaser/hero.webp')"
```

### Hidden sections (Explainers, Gallery)

**Explainers** and **Gallery** are unlinked from the site until they have
content; their pages and data still build. To bring one back:

- **Nav link:** re-add its entry to the `nav` array in
  [`src/layouts/Base.astro`](src/layouts/Base.astro).
- **Landing page:** un-comment its block in
  [`src/pages/index.astro`](src/pages/index.astro) (search for the marker
  comment, e.g. `Gallery preview hidden` or `Explainers hidden`).

## Scarves (16K teaser deep-zoom viewer)

The `/scarves` page shows the full 16K teaser render (too large for a browser to
decode as one image) via a tiled pyramid + [OpenSeadragon](https://openseadragon.github.io).
The landing hero links to it.

- **Tiles** live in `public/scarves/` (`teaser.dzi` + `teaser_files/`,
  committed). Regenerate from the 16K master with the local helper (`sharp` does
  the tiling):

  ```bash
  node scripts/make-scarves-tiles.mjs "D:/path/to/16k_master.jpg"
  ```

- **Viewer** is the `openseadragon` npm package (bundled per-page). Only its
  button images are served statically, vendored in
  `public/vendor/openseadragon/images/` (refresh after upgrading — see that
  folder's README).

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
