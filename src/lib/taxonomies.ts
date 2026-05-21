import type { CollectionEntry } from "astro:content";

export const TaxonomyCollectionNames = ["tags", "threads"] as const;
export type TaxonomyCollection = (typeof TaxonomyCollectionNames)[number];
export type TaxonomyEntry = CollectionEntry<TaxonomyCollection>;
