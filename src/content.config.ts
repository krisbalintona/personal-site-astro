import { defineCollection } from "astro:content";
import sluggify from "@lib/sluggify.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

function dateToPostId(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    String(date.getFullYear()) +
    pad(date.getMonth() + 1) +
    pad(date.getDate()) +
    pad(date.getHours()) +
    pad(date.getMinutes())
  );
}

const postSchema = z
  .object({
    title: z.string().default("Untitled"),
    date: z.date().default(new Date("1970-01-01")),
    draft: z.boolean().default(true),
  })
  .transform((data) => ({
    ...data,
    slug: sluggify(data.title),
    postId: dateToPostId(data.date),
  }));

// Extract the type of the parsed output of `postSchema`.  See
// https://v3.zod.dev/?id=type-inference
export type Post = z.infer<typeof postSchema>;

const articles = defineCollection({
  loader: glob({ pattern: "*/index.mdx", base: "./src/lib/posts" }),
  schema: postSchema,
});

export const collections = { articles };
