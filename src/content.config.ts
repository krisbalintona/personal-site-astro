import { baseContentShape } from "@lib/entries";
import mdFrontmatterLoader from "@lib/mdFrontmatterGlob.ts";
import { postSchema } from "@lib/posts.ts";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import { type CollectionEntry, defineCollection } from "astro:content";

// * Posts

const postSources = [
  {
    pattern: "*/index.mdx",
    base: "src/content/articles/",
  },
  {
    pattern: "*/index.mdx",
    base: "src/content/notes/",
  },
  {
    pattern: "*/index.mdx",
    base: "src/content/documents/",
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

const documents = defineCollection({
  loader: glob({
    pattern: "*/index.mdx",
    base: "./src/content/documents",
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
export const collections = {
  articles,
  notes,
  documents,
  tags,
  threads,
  standalone,
};
