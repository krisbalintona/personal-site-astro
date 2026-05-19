import { type CollectionEntry, getCollection } from "astro:content";
import { rssSchema } from "@astrojs/rss";
import { z } from "astro/zod";
import slugify from "slugify";
import type { z as zType } from "zod/v4";

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

export const baseContentShape = {
  title: z.string().default("Untitled"),
  draft: z.boolean().default(true),
};

// Zod does not support .extend() on transformed schemas.  Since we
// need to apply a transform to compute `titleSlug` and
// `permalinkSlug`, we expose this function instead to allow extending
// the base schema shape (`baseExpressionSchema`) while reapplying the
// transform.
export function extendExpressionSchema<T extends z.ZodRawShape>(shape: T) {
  // See
  // https://github.com/withastro/astro/tree/main/packages/astro-rss
  // for all properties of `rssSchema`.  Although all the properties
  // in `rssSchema` are typed as optional, RSS feeds themselves to
  // have required XML fields.
  return rssSchema
    .extend(baseContentShape)
    .extend({ pubDate: z.coerce.date().default(new Date("1970-01-01")) })
    .extend(shape)
    .transform((data) => {
      const d = data as zType.infer<typeof rssSchema> &
        zType.infer<zType.ZodObject<typeof baseContentShape>>;
      const titleSlug = slugify(
        d.title ?? "",
        { strict: true } // Strips special characters like colons
      );
      return {
        ...data,
        titleSlug,
        permalinkSlug:
          d.pubDate && d.draft === false ? dateToPostId(d.pubDate) : titleSlug,
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
