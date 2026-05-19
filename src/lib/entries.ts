import type { AnyCollectionEntry } from "@src/content.config.ts";
import { $path } from "astro-typesafe-routes/path";

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

// * Drafts

/**
 * Return true if `entry` is published.  An entry is considered
 * published when we are in a dev environment or when `entry` is not a
 * draft (including if the draft property is absent).
 *
 * @param post - A collection entry from any collection.
 * @returns True if `entry` is published, false otherwise.
 */
export function isPublished(entry: AnyCollectionEntry) {
  return (
    import.meta.env.DEV || ("draft" in entry.data ? !entry.data.draft : true)
  );
}

// * URLs

export function getEntryUrl(
  entry: AnyCollectionEntry,
  anchor?: string
): string {
  const base = getEntryBasePath(entry);
  return anchor ? `${base}#${anchor}` : base;
}

function getEntryBasePath(entry: AnyCollectionEntry): string {
  switch (entry.collection) {
    case "articles":
      return $path({
        to: "/articles/[titleSlug]",
        params: { titleSlug: entry.data.titleSlug },
      });
    case "notes":
      return $path({
        to: "/notes/[titleSlug]",
        params: { titleSlug: entry.data.titleSlug },
      });
    case "tags":
      return $path({ to: "/tags/[tag]", params: { tag: entry.data.title } });
    default:
      throw new Error(`No URL mapping for collection "${entry.collection}"`);
  }
}
