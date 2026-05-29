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
const ASTRO_MIGRATION_DATE = new Date("2026-05-24");

function dateToLegacyStableId(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");

  // Hugo generated permalinks in Chicago local time (CST = UTC-6, CDT
  // = UTC-5).  We hardcode CDT (-5h = -300min) since that matches the
  // old stable IDs.
  const CHICAGO_OFFSET_MS = -5 * 60 * 60 * 1000;
  const local = new Date(date.getTime() + CHICAGO_OFFSET_MS);

  return (
    String(local.getUTCFullYear()) +
    pad(local.getUTCMonth() + 1) +
    pad(local.getUTCDate()) +
    pad(local.getUTCHours()) +
    pad(local.getUTCMinutes())
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
  subtitle: z.string().optional(),
  tags: z.array(reference("tags")).optional(),
  threads: z.array(reference("threads")).optional(),
  redirects: z
    .array(
      z
        .string()
        .refine(
          (path) => /^\/.*[^/]$/.test(path),
          "Redirect path must start with '/' and must not end with '/'",
        ),
    )
    .optional(),
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
