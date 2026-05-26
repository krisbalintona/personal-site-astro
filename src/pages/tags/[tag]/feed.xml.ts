import { SITE_TITLE } from "@lib/consts";
import { getContentCollection, titleToUrlSlug } from "@lib/entries";
import { buildRSSItems, makeRSSFeed } from "@lib/rss.ts";
import { allExpressions } from "@src/lib/expressions";
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
  const title = `${SITE_TITLE} — #${tag.data.title}`;
  const description =
    tag.data.description ?? `Entries tagged with "${tag.data.title}"`;
  const items = await buildRSSItems(
    await allExpressions(
      (e) => e.data.tags?.some((t) => t.id === tag.id) ?? false,
    ),
  );

  return makeRSSFeed(context, title, description, items);
}
