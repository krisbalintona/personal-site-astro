import { rssSchema } from "@astrojs/rss";
import {
  baseContentShape,
  getContentCollection,
  titleToUrlSlug,
} from "@lib/entries";
import { z } from "astro/zod";
import { type CollectionEntry, reference } from "astro:content";
import { $path } from "astro-typesafe-routes/path";

// The date the site was migrated from Hugo to Astro. Posts published
// before this date used local time for their stable IDs (matching
// Hugo's permalink scheme) rather than UTC.
const ASTRO_MIGRATION_DATE = new Date("2025-05-26");

function dateToLegacyStableId(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    String(date.getFullYear()) +
    pad(date.getMonth() + 1) +
    pad(date.getDate()) +
    pad(date.getHours()) +
    pad(date.getMinutes())
  );
}

export function getExpressionLegacyId(
  expression: ExpressionEntry,
): string | undefined {
  const pubDate = expression.data.pubDate;
  if (!pubDate || pubDate >= ASTRO_MIGRATION_DATE) return undefined;
  return titleToUrlSlug(dateToLegacyStableId(pubDate));
}

function dateToStableId(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    String(date.getUTCFullYear()) +
    pad(date.getUTCMonth() + 1) +
    pad(date.getUTCDate()) +
    pad(date.getUTCHours()) +
    pad(date.getUTCMinutes())
  );
}

export function getExpressionStableId(expression: ExpressionEntry): string {
  return titleToUrlSlug(
    expression.data.pubDate && expression.data.draft === false
      ? dateToStableId(expression.data.pubDate)
      : expression.data.title,
  );
}

export function getExpressionPermalink(expression: ExpressionEntry): string {
  return $path({
    to: "/posts/[stableId]",
    params: { stableId: getExpressionStableId(expression) },
  });
}

// See https://github.com/withastro/astro/tree/main/packages/astro-rss
// for all properties of `rssSchema`.  Although all the properties in
// `rssSchema` are typed as optional, RSS feeds themselves to have
// required XML fields.
export const expressionSchema = rssSchema.extend(baseContentShape).extend({
  pubDate: z.coerce.date().default(new Date("1970-01-01")),
  tags: z.array(reference("tags")).optional(),
  threads: z.array(reference("threads")).optional(),
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
