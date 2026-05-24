import { rssSchema } from "@astrojs/rss";
import { z } from "astro/zod";
import { type CollectionEntry, getCollection, reference } from "astro:content";
import slugify from "slugify";
import type { z as zType } from "zod/v4";
import { baseContentShape, isPublished } from "@lib/entries";

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
export const expressionSchema = rssSchema
  .extend(baseContentShape)
  .extend({
    pubDate: z.coerce.date().default(new Date("1970-01-01")),
    tags: z.array(reference("tags")).optional(),
    threads: z.array(reference("threads")).optional(),
  })
  .transform((data) => {
    const d = data as zType.infer<typeof rssSchema> &
      zType.infer<zType.ZodObject<typeof baseContentShape>>;
    const titleSlug = slugify(
      d.title ?? "",
      { strict: true }, // Strips special characters like colons
    );
    return {
      ...data,
      titleSlug,
      permalinkSlug:
        d.pubDate && d.draft === false ? dateToPostId(d.pubDate) : titleSlug,
    };
  });

export const ExpressionCollectionNames = ["articles", "notes"] as const;
export type ExpressionCollection = (typeof ExpressionCollectionNames)[number];
export type ExpressionEntry = CollectionEntry<ExpressionCollection>;

export async function allExpressions(
  filter?: (entry: CollectionEntry<ExpressionCollection>) => boolean,
): Promise<ExpressionEntry[]> {
  return (
    await Promise.all(
      ExpressionCollectionNames.map((name) => getCollection(name, filter)),
    )
  ).flat();
}
