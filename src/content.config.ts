import {
  type CollectionEntry,
  defineCollection,
  reference,
} from "astro:content";
import { baseContentShape, extendExpressionSchema } from "@lib/expressions.ts";
import mdFrontmatterLoader from "@lib/mdFrontmatterGlob.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

const articles = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/articles",
  }),
  schema: extendExpressionSchema({
    tags: z.array(reference("tags")).optional(),
    threads: z.array(reference("threads")).optional(),
  }),
});

const tags = defineCollection({
  loader: mdFrontmatterLoader({
    sources: [
      {
        pattern: "*/index.mdx",
        base: "src/content/articles/",
      },
    ],
    sourceField: "tags",
    contentPattern: "*/index.mdx",
    contentBase: "./src/content/tags",
  }),
  schema: z.object(baseContentShape),
});

const threads = defineCollection({
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
    sourceField: "threads",
    contentPattern: "*/index.mdx",
    contentBase: "./src/content/threads",
  }),
  schema: z.object(baseContentShape),
});

const standalone = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/standalone",
  }),
  schema: z.object(baseContentShape),
});

export type AnyCollectionName = keyof typeof collections;
export type AnyCollectionEntry = CollectionEntry<AnyCollectionName>;
export const collections = { articles, tags, threads, standalone };
