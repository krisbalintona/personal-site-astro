import { allPostEntries } from "@lib/posts.ts";

export async function getAllTags(): Promise<string[]> {
  const tagSet = new Set<string>();
  const entries = await allPostEntries();

  for (const entry of entries) {
    for (const tag of entry.data.tags ?? []) {
      tagSet.add(tag);
    }
  }

  return [...tagSet];
}
