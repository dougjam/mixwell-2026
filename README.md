![Detail of the Bouquet scarf from the Mixwell teaser render](public/images/mixwell-banner-bouquet.webp)

# Mixwell: Sharp 2D Fluid Brushes for Progressive Physics-Based Mixing

Released code and project website for the paper:

> **Mixwell: Sharp 2D Fluid Brushes for Progressive Physics-Based Mixing**
> Doug L. James and Ethan James
> ACM Transactions on Graphics 45(4), Article 79 (SIGGRAPH 2026, Best Paper)
> DOI: [10.1145/3811312](https://dl.acm.org/doi/10.1145/3811312)

**Project page:** <https://dougjam.github.io/mixwell-2026/> — paper and
supplement, video, interactive WebGPU demo, Shadertoy gallery, code browser,
and a deep-zoom viewer for the 16K teaser render.

## Looking for the code?

The released shader libraries live under [`public/code/`](public/code/):

| Path | Contents |
| --- | --- |
| [`public/code/glsl/`](public/code/glsl/) | GLSL: full Mixwell library and a brush-only lite build |
| [`public/code/hlsl/`](public/code/hlsl/) | HLSL: full library and a brush-only lite build |
| [`public/code/opencl/`](public/code/opencl/) | OpenCL kernels for Houdini Copernicus, plus the `hmarbleWeb.hipnc` example project |
| [`public/code/osl/`](public/code/osl/) | Redshift OSL shaders, plus the `scarvesWeb.hipnc` teaser scene (includes test quads, so it renders out of the box) |

You do not need to clone this repository (it also contains the website): every
file can be read with syntax highlighting and downloaded individually from the
[Code &amp; Libraries page](https://dougjam.github.io/mixwell-2026/code), and
live Shadertoy demonstrations built on the GLSL library are in the
[shader gallery](https://dougjam.github.io/mixwell-2026/demos/shaders).

## Repository layout

| Path | What it is |
| --- | --- |
| `public/code/` | The released shader libraries and Houdini projects (above) |
| `public/demos/webgpu/app/` | The compiled interactive WebGPU demo bundle |
| `src/`, `public/` | The project website (an [Astro](https://astro.build) static site) |
| [`REPLICABILITY.md`](REPLICABILITY.md) | How to reproduce representative paper results |

## Replicability

See [`REPLICABILITY.md`](REPLICABILITY.md). Representative paper results can be
reproduced in seconds from the Shadertoy demonstrations (no installation), and
several figures regenerate from the Houdini project in the free non-commercial
Apprentice edition.

## License

All released code is MIT licensed (see [`LICENSE`](LICENSE)). Each source file
carries a two-line SPDX header, so the license travels with any file copied out
of the repository.

## Website maintenance

The website is built with Astro and deployed to GitHub Pages by GitHub Actions
on every push to `main`. Build, content-editing, and asset instructions are in
[`MAINTAINING.md`](MAINTAINING.md).
