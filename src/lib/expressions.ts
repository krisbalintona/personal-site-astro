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
export const baseExpressionSchema = rssSchema.extend({
  title: z.string().default("Untitled"),
  pubDate: z.coerce.date().default(new Date("1970-01-01")),
  draft: z.boolean().default(true),
});

// Zod does not support .extend() on transformed schemas.  Since we
// need to apply a transform to compute `titleSlug` and
// `permalinkSlug`, we expose this function instead to allow extending
// the base schema shape (`baseExpressionSchema`) while reapplying the
// transform.
export function extendExpressionSchema<T extends z.ZodRawShape>(shape: T) {
  return baseExpressionSchema.extend(shape).transform((data) => {
    // `data` is typed as the extended schema's output, which
    // Typescript cannot resolve to a concrete type through the
    // generic.  We cast to the base type since we know
    // `baseExpressionSchema`'s fields are always present after
    // .extend() to make Typescript happy.
    const base = data as z.infer<typeof baseExpressionSchema>;
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

export const expressionSchema = extendExpressionSchema({});

export const ExpressionCollectionNames = ["articles"] as const;
export type ExpressionCollection = (typeof ExpressionCollectionNames)[number];
export type ExpressionEntry = CollectionEntry<ExpressionCollection>;

export async function allExpressions(
  filter?: (entry: CollectionEntry<ExpressionCollection>) => boolean
): Promise<ExpressionEntry[]> {
  return (
    await Promise.all(
      ExpressionCollectionNames.map((name) => getCollection(name, filter))
    )
  ).flat();
}
