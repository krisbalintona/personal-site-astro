import { baseContentShape, publishedContentShape } from "@lib/entries";
import mdFrontmatterLoader from "@lib/mdFrontmatterGlob.ts";
import { postSchema } from "@lib/posts.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import { type CollectionEntry, defineCollection } from "astro:content";

// * Content
// ** Posts (time-bound)

const postSources = [
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
  schema: postSchema,
});

const notes = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/notes",
  }),
  schema: postSchema,
});

// ** Non-time-bound

const standalone = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/standalone",
  }),
  schema: postSchema,
});

// * Taxonomy

const tags = defineCollection({
  loader: mdFrontmatterLoader({
    sources: postSources,
    sourceField: "tags",
    contentPattern: "*/index.mdx",
    contentBase: "./src/content/tags",
  }),
  schema: z.object(baseContentShape),
});

const threads = defineCollection({
  loader: mdFrontmatterLoader({
    sources: postSources,
    sourceField: "threads",
    contentPattern: "*/index.mdx",
    contentBase: "./src/content/threads",
  }),
  schema: z.object(baseContentShape),
});

// * Other

const other = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/other",
  }),
  schema: z.object(publishedContentShape),
});

// * Export variables

export type AnyCollectionName = keyof typeof collections;
export type AnyCollectionEntry = CollectionEntry<AnyCollectionName>;
export const collections = {
  articles,
  notes,
  standalone,
  tags,
  threads,
  other,
};
