import { type CollectionEntry, defineCollection } from "astro:content";
import { postSchema } from "@lib/posts.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

const articles = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/articles",
  }),
  schema: postSchema,
});

const tags = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/tags",
  }),
  schema: z.object({
    name: z.string(),
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
export const collections = { articles, tags, standalone };
