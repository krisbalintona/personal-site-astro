import type { AnyCollectionEntry } from "@src/content.config.ts";
import { $path } from "astro-typesafe-routes/path";

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
    case "tags":
      return $path({ to: "/tags/[tag]", params: { tag: entry.data.name } });
    default:
      throw new Error(`No URL mapping for collection "${entry.collection}"`);
  }
}
