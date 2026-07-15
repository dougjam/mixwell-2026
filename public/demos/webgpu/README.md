# WebGPU demo bundle

The built WebGPU demo lives in the `app/` subfolder here and is served as a
standalone, full-screen page. The `/demos/webgpu` page detects WebGPU support and
shows a **Launch the demo** button that opens it.

## Refreshing the demo

The demo is built elsewhere (the Mixwell project's Emscripten build). To update
it, copy these **five files** from the build output into `app/`, overwriting the
old ones:

```
Mixwell.html
Mixwell.js
Mixwell.wasm
Mixwell.data
Mixwell.worker.js
```

Do **not** delete or overwrite these two site-maintained files in `app/`:

```
index.html              <- bootstrap that enables cross-origin isolation, then loads Mixwell.html
coi-serviceworker.js    <- injects COOP/COEP headers (see "Why" below)
```

> **Keep the bundle binary in git.** `Mixwell.js` indexes `Mixwell.data` by exact
> byte offset, so a single altered byte corrupts the packed shaders and the demo
> fails to load (with a shader-parse error) for everyone but you locally. The repo
> root `.gitattributes` marks `public/demos/webgpu/app/**` (and `*.wasm`/`*.data`)
> as `binary` so git never normalizes line endings on these files — do not remove
> that rule, and after refreshing verify the served `Mixwell.data` is byte-for-byte
> identical to the build output.

## Why the extra wrapper?

The demo uses multithreading (pthreads / SharedArrayBuffer), which browsers only
allow on **cross-origin isolated** pages — i.e. pages served with
`Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`. GitHub Pages can't set response
headers, so `coi-serviceworker.js` adds them client-side via a service worker,
and `index.html` waits for isolation before handing off to `Mixwell.html`.

The demo is **not** embedded in an iframe: a framed page can only be cross-origin
isolated if every ancestor is too, which would force those headers onto the whole
site. Launching it as its own page keeps the isolation self-contained.

## Rules

- Keep the bundle lean — no large extra assets. `Mixwell.wasm` is a few MB, which
  is fine; don't add anything much larger.
- No video files. Use a YouTube embed (config `links.supplementalVideoId`) for
  any recorded walkthrough.
