import { defineCollection } from "astro:content";
import { dateToPostId, postSchema } from "@lib/content.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import slugify from "slugify";

const articles = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/posts",
    generateId: ({ entry, data }) =>
      // I use the entry ID as the permalink "slug"
      data?.date && data?.draft === false
        ? dateToPostId(data.date as Date)
        : entry.split("/")[0],
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

export const collections = { articles, tags };
