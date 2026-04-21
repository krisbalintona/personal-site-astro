import { getCollection } from "astro:content";
import { collections, type PostCollectionNames } from "@src/content.config.ts";

export async function getAllTags(): Promise<string[]> {
  const collectionNames = Object.keys(collections) as PostCollectionNames[];

  const allEntries = await Promise.all(
    collectionNames.map((name) => getCollection(name))
  );

  const tagSet = new Set<string>();
  for (const entries of allEntries) {
    for (const entry of entries) {
      for (const tag of entry.data.tags ?? []) {
        tagSet.add(tag);
      }
    }
  }

  return [...tagSet];
}
