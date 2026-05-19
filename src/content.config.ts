import { type CollectionEntry, defineCollection } from "astro:content";
import { baseContentShape, expressionSchema } from "@lib/expressions.ts";
import mdFrontmatterLoader from "@lib/mdFrontmatterGlob.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

const articles = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/articles",
  }),
  schema: expressionSchema,
});

const notes = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/notes",
  }),
  schema: expressionSchema,
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
        base: "src/content/notes/",
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
export const collections = { articles, notes, tags, threads, standalone };
