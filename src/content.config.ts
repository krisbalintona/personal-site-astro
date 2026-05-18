import {
  type CollectionEntry,
  defineCollection,
  reference,
} from "astro:content";
import mdFrontmatterLoader from "@lib/mdFrontmatterGlob.ts";
import { extendPostSchema, postSchema } from "@lib/posts.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

const articles = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/articles",
  }),
  schema: extendPostSchema({
    tags: z.array(reference("tags")).optional(),
    series: z.array(reference("series")).optional(),
  }),
});

const tags = defineCollection({
  loader: mdFrontmatterLoader({
    sources: [
      {
        pattern: "*/index.mdx",
        base: "src/content/articles/",
      },
      {
        pattern: "*/index.mdx",
        base: "src/content/standalone",
      },
    ],
    sourceField: "tags",
    contentPattern: "*/index.mdx",
    contentBase: "./src/content/tags",
  }),
});

const series = defineCollection({
  loader: mdFrontmatterLoader({
    sources: [
      {
        pattern: "*/index.mdx",
        base: "src/content/articles/",
      },
      {
        pattern: "*/index.mdx",
        base: "src/content/standalone",
      },
    ],
    sourceField: "series",
    contentPattern: "*/index.mdx",
    contentBase: "./src/content/series",
  }),
});

const standalone = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/standalone",
  }),
  schema: postSchema,
});

export type AnyCollectionName = keyof typeof collections;
export type AnyCollectionEntry = CollectionEntry<AnyCollectionName>;
export const collections = { articles, tags, series, standalone };
