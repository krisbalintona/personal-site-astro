import { isDev } from "@lib/consts.ts";
import type {
  AnyCollectionEntry,
  AnyCollectionName,
} from "@src/content.config.ts";
import type { AstroComponentFactory } from "astro/runtime/server/index.js";
import { z } from "astro/zod";
import {
  type CollectionEntry,
  getCollection,
  getEntries,
  getEntry,
  render,
} from "astro:content";
import { $path } from "astro-typesafe-routes/path";
import slugify from "slugify";

// * Content
// An API layer for my site's content content.

export const baseContentShape = {
  title: z.string().default("Untitled"),
  slug: z.string().optional(),
  draft: z.boolean().default(true),
  description: z.string().optional(),
};

export const publishedContentShape = {
  ...baseContentShape,
  pubDate: z.coerce.date().default(new Date("1970-01-01")),
  lastMod: z.coerce.date().optional(),
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
};

/**
 * Return true if `entry` is published.  An entry is considered
 * published when we are in a dev environment, when `entry` has no
 * associated content file (i.e., it is a stub entry), or when `entry`
 * is not a draft.
 *
 * @param entry - A collection entry from any collection.
 * @returns True if `entry` is published, false otherwise.
 */
function isPublished(entry: AnyCollectionEntry) {
  return isDev || !entry.filePath || !entry.data.draft;
}

/**
 * Drop-in replacement for `getCollection` that automatically excludes
 * draft entries in production.  Accepts an optional additional filter
 * that is AND-ed with the draft check.
 *
 * Always use this instead of `getCollection` directly.
 */
export function getContentCollection<C extends AnyCollectionName>(
  collection: C,
  filter?: (entry: CollectionEntry<C>) => boolean,
): Promise<CollectionEntry<C>[]> {
  return getCollection(
    collection,
    (entry) =>
      isPublished(entry as AnyCollectionEntry) &&
      (filter ? filter(entry) : true),
  );
}

/**
 * Drop-in replacement for `getEntry` that returns `undefined` if the
 * entry is a draft in production.
 *
 * Always use this instead of `getEntry` directly.
 */
export async function getContentEntry<C extends AnyCollectionName>(
  collection: C,
  id: string,
): Promise<CollectionEntry<C> | undefined> {
  const entry = (await getEntry(collection, id)) as
    | CollectionEntry<C>
    | undefined;
  if (!entry || !isPublished(entry as AnyCollectionEntry)) return undefined;
  return entry;
}

/**
 * Drop-in replacement for `getEntries` that automatically excludes
 * draft entries in production.
 *
 * Always use this instead of `getEntries` directly.
 */
export async function getContentEntries<C extends AnyCollectionName>(
  entries: { collection: C; id: string }[],
): Promise<CollectionEntry<C>[]> {
  const resolved = await getEntries(entries);
  return resolved.filter((entry) => isPublished(entry as AnyCollectionEntry));
}

/**
 * Render the content of `entry` if it exists and is published.
 * Returns `{ Content: undefined }` if the entry is absent or a draft
 * in production.
 *
 * @param entry - Any collection entry, or undefined.
 * @returns The rendered `Content` component, or `undefined`.
 */
export async function renderContent(
  entry: AnyCollectionEntry | undefined,
): Promise<{ Content: AstroComponentFactory | undefined }> {
  if (!entry || !isPublished(entry)) return { Content: undefined };
  return await render(entry);
}

// * Dates

const MILLIS_AND_UTC = /\.\d{3}Z$/;

export function toDateTimeAttribute(date: Date): string {
  const offset = -date.getTimezoneOffset();
  const pad = (n: number) => String(n).padStart(2, "0");
  const sign = offset >= 0 ? "+" : "-";
  const hours = pad(Math.floor(Math.abs(offset) / 60));
  const minutes = pad(Math.abs(offset) % 60);
  return date
    .toISOString()
    .replace(MILLIS_AND_UTC, `${sign}${hours}:${minutes}`);
}

export function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

// * URLs

export function titleToUrlSlug(title: string): string {
  return slugify(title, { lower: true, strict: true });
}

export function getEntryUrl(
  entry: AnyCollectionEntry,
  anchor?: string,
): string {
  switch (entry.collection) {
    case "articles":
      return $path({
        to: "/articles/[title]",
        params: { title: titleToUrlSlug(entry.data.title) },
        hash: anchor,
      });
    case "notes":
      return $path({
        to: "/notes/[title]",
        params: { title: titleToUrlSlug(entry.data.title) },
        hash: anchor,
      });
    case "standalone":
      return $path({
        to: "/[standaloneTitle]",
        params: { standaloneTitle: titleToUrlSlug(entry.data.title) },
        hash: anchor,
      });
    case "tags":
      return $path({
        to: "/tags/[tag]",
        params: { tag: titleToUrlSlug(entry.data.title) },
        hash: anchor,
      });
    case "threads":
      return $path({
        to: "/threads/[thread]",
        params: { thread: titleToUrlSlug(entry.data.title) },
        hash: anchor,
      });
    default:
      throw new Error(`No URL mapping for collection "${entry.collection}"`);
  }
}
