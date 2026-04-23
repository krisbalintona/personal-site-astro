import type { PostEntry } from "@lib/posts.ts";

/**
 * Return true if `post` is published, that is, whether it is a draft.
 *
 * @param post - A collection entry from any collection.
 * @returns True if `post` is published, false otherwise.
 */
export default function (post: PostEntry) {
  return import.meta.env.DEV || !post.data.draft;
}
