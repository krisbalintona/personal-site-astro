import type { AnyPost } from "@src/content.config.ts";

/**
 * Return true if `post` is published, that is, whether it is a draft.
 *
 * @param post - A collection entry from any collection.
 * @returns True if `post` is published, false otherwise.
 */
export default function (post: AnyPost) {
  return import.meta.env.DEV || !post.data.draft;
}
