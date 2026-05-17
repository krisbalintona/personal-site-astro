import { type CollectionEntry, defineCollection } from "astro:content";
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
    series: z.array(z.string()).optional(),
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
