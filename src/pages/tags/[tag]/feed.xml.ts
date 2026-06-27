import { SITE_TITLE } from "@lib/consts";
import {
  getContentCollection,
  titleToUrlSlug,
  toPlainTitle,
} from "@lib/entries";
import { buildRSSItems, makeRSSFeed } from "@lib/rss.ts";
import { allPosts } from "@src/lib/posts";
import type { APIContext } from "astro";
import { type CollectionEntry } from "astro:content";
import { createRoute } from "astro-typesafe-routes/create-route";

export const Route = createRoute({ routeId: "/tags/[tag]/feed.xml" });

export const getStaticPaths = Route.createGetStaticPaths(async () =>
  (await getContentCollection("tags")).map((tag) => ({
    params: { tag: titleToUrlSlug(tag.data.title) },
    props: { tag },
  })),
);

export async function GET(
  context: APIContext<{ tag: CollectionEntry<"tags"> }>,
) {
  const { tag } = context.props;
  const title = `${SITE_TITLE} — #${toPlainTitle(tag.data.title)}`;
  const description =
    tag.data.description ??
    `Entries tagged with "${toPlainTitle(tag.data.title)}"`;
  const items = await buildRSSItems(
    await allPosts((e) => e.data.tags?.some((t) => t.id === tag.id) ?? false),
  );

  return makeRSSFeed(context, title, description, items);
}
