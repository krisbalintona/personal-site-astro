import { type CollectionEntry, defineCollection } from "astro:content";
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
    tags: z.array(z.string()).optional(),
  })
  .transform((data) => ({
    ...data,
    slug: sluggify(data.title),
    // There is only a postId once the post is published (and
    // therefore having a date that can be converted to an ID)
    postId: data.draft ? null : dateToPostId(data.date),
  }));

// Extract the type of the parsed output of `postSchema`.  See
// https://v3.zod.dev/?id=type-inference
export type Post = z.infer<typeof postSchema>;

const articles = defineCollection({
  loader: glob({ pattern: "*/index.mdx", base: "./src/content/posts" }),
  schema: postSchema,
});

export const collections = { articles };

// FIXME 2026-04-19: Right now all my collections are post
// collections.  However, in the future, once I have non-post
// collections, I should do something more like:
//
// type PostCollectionNames = "articles";
//
type PostCollectionNames = keyof typeof collections;
export type AnyPost = CollectionEntry<PostCollectionNames>;
