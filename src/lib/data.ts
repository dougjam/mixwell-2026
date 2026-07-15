// Typed loaders for the hand-editable YAML data files under src/data/.
// The YAML file contents are inlined at build time via Vite's import.meta.glob
// (query '?raw'), so there is no runtime filesystem access in the bundled output.

import yaml from 'js-yaml';

const rawFiles = import.meta.glob<string>('../data/*.yaml', {
  query: '?raw',
  import: 'default',
  eager: true,
});

function loadYaml<T>(file: string): T {
  const key = `../data/${file}`;
  const raw = rawFiles[key];
  if (raw === undefined) {
    throw new Error(`Data file not found: src/data/${file}`);
  }
  return yaml.load(raw) as T;
}

// --- Types -------------------------------------------------------------------

export interface Author {
  name: string;
  affiliation: string;
  orcid: string | null;
  homepage: string | null;
  linkedin: string | null;
}

export interface SiteConfig {
  title: string;
  venue: {
    full: string;
    short: string;
    volume: string;
    number: string;
    articleno: string;
    numpages: string;
    published: string;
  };
  doi: string;
  paperUrl: string;
  authors: Author[];
  abstract: string;
  badges: string[];
  teaser: { image: string; alt: string; teaserVideoId: string | null };
  links: {
    paperPdf: string | null;
    supplementalPdf: string | null;
    supplementalVideoId: string | null;
    talkVideoId: string | null;
    codeRepo: string | null;
    data: string | null;
  };
  codeRepoUrl: string;
  bibtex: string;
  news: { date: string; text: string; url?: string }[];
}

export interface DemoCard {
  id: string;
  title: string;
  blurb: string;
  thumbnail: string;
  route?: string;
  url?: string;
}

export interface ShaderEntry {
  id: string;
  title: string;
  explanation: string;
  thumbnail: string;
  viewUrl: string;
  embedUrl?: string;
}

export interface Library {
  id: string;
  name: string;
  languageLabel: string;
  language: string;
  description: string;
  repoFolder: string;
  download: string | null;
  snippet: string;
}

export interface GalleryItem {
  id: string;
  caption: string;
  thumbnail: string;
  full: string;
  master: string | null;
}

// --- Accessors ---------------------------------------------------------------

export const siteConfig: SiteConfig = loadYaml<SiteConfig>('site.config.yaml');

export const demos: DemoCard[] = loadYaml<{ demos: DemoCard[] }>('demos.yaml').demos ?? [];

export const shaders: ShaderEntry[] =
  loadYaml<{ shaders: ShaderEntry[] }>('shaders.yaml').shaders ?? [];

export const libraries: Library[] =
  loadYaml<{ libraries: Library[] }>('libraries.yaml').libraries ?? [];

export const gallery: GalleryItem[] =
  loadYaml<{ gallery: GalleryItem[] }>('gallery.yaml').gallery ?? [];

// --- Derived helpers ---------------------------------------------------------

/** Join a library's repo-relative folder to the configured code repo URL. */
export function repoFolderUrl(repoFolder: string): string {
  const base = siteConfig.codeRepoUrl.replace(/\/+$/, '');
  const folder = repoFolder.replace(/^\/+/, '');
  // GitHub browses folders under /tree/main/<folder>.
  return `${base}/tree/main/${folder}`;
}

/** Derive a Shadertoy embed URL from a view URL if no explicit embed is set. */
export function shaderEmbedUrl(entry: ShaderEntry): string {
  if (entry.embedUrl) return entry.embedUrl;
  return entry.viewUrl.replace('/view/', '/embed/');
}
