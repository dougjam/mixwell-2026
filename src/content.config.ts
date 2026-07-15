import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Explainer articles: MDX files under src/content/explainers/.
const explainers = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/explainers' }),
  schema: z.object({
    title: z.string(),
    blurb: z.string(),
    // Thumbnail is a site-relative path under public/ (base path added at render time).
    thumbnail: z.string(),
    order: z.number().default(999),
    draft: z.boolean().default(false),
  }),
});

export const collections = { explainers };
