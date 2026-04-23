import { type CollectionEntry, defineCollection } from "astro:content";
import { rssSchema } from "@astrojs/rss";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import slugify from "slugify";

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

// See https://github.com/withastro/astro/tree/main/packages/astro-rss
// for all properties of `rssSchema`.  Although all the properties in
// `rssSchema` are typed as optional, RSS feeds themselves to have
// required XML fields.
const postSchema = rssSchema
  .extend({
    title: z.string().default("Untitled"),
    pubDate: z.coerce.date().default(new Date("1970-01-01")),
    draft: z.boolean().default(true),
    tags: z.array(z.string()).optional(),
  })
  .transform((data) => ({
    ...data,
    slug: slugify(data.title),
  }));

// Extract the type of the parsed output of `postSchema`.  See
// https://v3.zod.dev/?id=type-inference
export type Post = z.infer<typeof postSchema>;

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

export type PostCollectionNames = "articles";
export type AnyPost = CollectionEntry<PostCollectionNames>;
