import { rssSchema } from "@astrojs/rss";
import {
  getContentCollection,
  type PlainTitle,
  publishedContentShape,
  titleToUrlSlug,
  toPlainTitle,
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

export function getPostLegacyId(post: PostEntry): string | undefined {
  const pubDate = post.data.pubDate;
  if (!pubDate || pubDate >= ASTRO_MIGRATION_DATE) return undefined;
  return titleToUrlSlug(dateToLegacyStableId(pubDate) as PlainTitle);
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

export function getPostStableId(post: PostEntry): string {
  return titleToUrlSlug(
    post.data.pubDate && post.data.draft === false
      ? (dateToStableId(post.data.pubDate) as PlainTitle)
      : toPlainTitle(post.data.title),
  );
}

export function getPostPermalink(post: PostEntry): string {
  return $path({
    to: "/posts/[stableId]",
    params: { stableId: getPostStableId(post) },
  });
}

// See https://github.com/withastro/astro/tree/main/packages/astro-rss
// for all properties of `rssSchema`.  Although all the properties in
// `rssSchema` are typed as optional, RSS feeds themselves to have
// required XML fields.
export const postSchema = rssSchema.extend(publishedContentShape).extend({
  tags: z.array(reference("tags")).optional(),
  threads: z.array(reference("threads")).optional(),
});

export const PostCollectionNames = ["articles", "notes"] as const;
export type PostCollection = (typeof PostCollectionNames)[number];
export type PostEntry = CollectionEntry<PostCollection>;

export async function allPosts(
  filter?: (entry: CollectionEntry<PostCollection>) => boolean,
): Promise<PostEntry[]> {
  return (
    await Promise.all(
      PostCollectionNames.map((name) => getContentCollection(name, filter)),
    )
  ).flat();
}
