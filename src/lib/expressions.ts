import { rssSchema } from "@astrojs/rss";
import { baseContentShape, getContentCollection } from "@lib/entries";
import { z } from "astro/zod";
import { type CollectionEntry, reference } from "astro:content";
import { $path } from "astro-typesafe-routes/path";
import slugify from "slugify";
import type { z as zType } from "zod/v4";

export function dateToPostId(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    String(date.getUTCFullYear()) +
    pad(date.getUTCMonth() + 1) +
    pad(date.getUTCDate()) +
    pad(date.getUTCHours()) +
    pad(date.getUTCMinutes())
  );
}

export function getExpressionPermalink(expression: ExpressionEntry): string {
  return $path({
    to: "/posts/[permalinkSlug]",
    params: { permalinkSlug: expression.data.permalinkSlug },
  });
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
      ExpressionCollectionNames.map((name) =>
        getContentCollection(name, filter),
      ),
    )
  ).flat();
}
