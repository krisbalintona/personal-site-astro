import { type CollectionEntry, defineCollection } from "astro:content";
import { postSchema } from "@lib/posts.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import slugify from "slugify";

const articles = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/posts",
  }),
  schema: postSchema,
});

const tags = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/tags",
    generateId: ({ entry, data }) =>
      data?.name ? slugify(data.name as string) : entry.split("/")[0],
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

export type CollectionName = keyof typeof collections;
export type AnyCollectionEntry = CollectionEntry<CollectionName>;
export const collections = { articles, tags, standalone };
