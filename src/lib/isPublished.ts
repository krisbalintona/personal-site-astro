import type { AnyCollectionEntry } from "@src/content.config.ts";

/**
 * Return true if `entry` is published.  An entry is considered
 * published when we are in a dev environment or when `entry` is not a
 * draft (including if the draft property is absent).
 *
 * @param post - A collection entry from any collection.
 * @returns True if `entry` is published, false otherwise.
 */
export default function (entry: AnyCollectionEntry) {
  return (
    import.meta.env.DEV || ("draft" in entry.data ? !entry.data.draft : true)
  );
}
