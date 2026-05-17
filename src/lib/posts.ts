import { type CollectionEntry, getCollection } from "astro:content";
import { rssSchema } from "@astrojs/rss";
import { z } from "astro/zod";
import slugify from "slugify";

export function dateToPostId(date: Date): string {
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
export const basePostSchema = rssSchema.extend({
  title: z.string().default("Untitled"),
  pubDate: z.coerce.date().default(new Date("1970-01-01")),
  draft: z.boolean().default(true),
  tags: z.array(z.string()).optional(),
});

// Zod does not support .extend() on transformed schemas.  Since we
// need to apply a transform to compute `titleSlug` and
// `permalinkSlug`, we expose this function instead to allow extending
// the base schema shape (`basePostSchema`) while reapplying the
// transform.
export function extendPostSchema<T extends z.ZodRawShape>(shape: T) {
  return basePostSchema.extend(shape).transform((data) => {
    // `data` is typed as the extended schema's output, which
    // Typescript cannot resolve to a concrete type through the
    // generic.  We cast to the base type since we know
    // basePostSchema's fields are always present after .extend() to
    // make Typescript happy.
    const base = data as z.infer<typeof basePostSchema>;
    const titleSlug = slugify(
      base.title,
      { strict: true } // Strips special characters like colons
    );
    return {
      ...data,
      titleSlug,
      permalinkSlug:
        base.pubDate && base.draft === false
          ? dateToPostId(base.pubDate as Date)
          : titleSlug,
    };
  });
}

export const postSchema = extendPostSchema({});

export const PostCollectionNames = ["articles"] as const;
export type PostCollection = (typeof PostCollectionNames)[number];
export type PostEntry = CollectionEntry<PostCollection>;

export async function allPostEntries(
  filter?: (entry: CollectionEntry<PostCollection>) => boolean
): Promise<PostEntry[]> {
  return (
    await Promise.all(
      PostCollectionNames.map((name) => getCollection(name, filter))
    )
  ).flat();
}
