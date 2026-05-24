import { expressionSchema } from "@lib/expressions.ts";
import mdFrontmatterLoader from "@lib/mdFrontmatterGlob.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import { type CollectionEntry, defineCollection } from "astro:content";
import { baseContentShape } from "@lib/entries";

// * Expressions

const expressionSources = [
  {
    pattern: "*/index.mdx",
    base: "src/content/articles/",
  },
  {
    pattern: "*/index.mdx",
    base: "src/content/notes/",
  },
];

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

// * Taxonomy

const tags = defineCollection({
  loader: mdFrontmatterLoader({
    sources: expressionSources,
    sourceField: "tags",
    contentPattern: "*/index.mdx",
    contentBase: "./src/content/tags",
  }),
  schema: z.object(baseContentShape),
});

const threads = defineCollection({
  loader: mdFrontmatterLoader({
    sources: expressionSources,
    sourceField: "threads",
    contentPattern: "*/index.mdx",
    contentBase: "./src/content/threads",
  }),
  schema: z.object(baseContentShape),
});

// * Other

const standalone = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/standalone",
  }),
  schema: z.object(baseContentShape),
});

// * Export variables

export type AnyCollectionName = keyof typeof collections;
export type AnyCollectionEntry = CollectionEntry<AnyCollectionName>;
export const collections = { articles, notes, tags, threads, standalone };
