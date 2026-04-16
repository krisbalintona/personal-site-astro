import { defineCollection } from "astro:content";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

const posts = defineCollection({
  loader: glob({ pattern: "*/index.mdx", base: "./src/lib/posts" }),
  schema: z.object({
    title: z.string().default("Untitled"),
    date: z.date().default(new Date("1970-01-01")),
  }),
});

export const collections = { posts };
