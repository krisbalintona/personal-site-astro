import { SITE_TITLE } from "@lib/consts";
import { getContentCollection, titleToUrlSlug } from "@lib/entries";
import { buildRSSItems, makeRSSFeed } from "@lib/rss.ts";
import { allExpressions } from "@src/lib/expressions";
import type { APIContext } from "astro";
import { type CollectionEntry } from "astro:content";
import { createRoute } from "astro-typesafe-routes/create-route";

export const Route = createRoute({ routeId: "/threads/[thread]/feed.xml" });

export const getStaticPaths = Route.createGetStaticPaths(async () =>
  (await getContentCollection("threads")).map((thread) => ({
    params: { thread: titleToUrlSlug(thread.data.title) },
    props: { thread },
  })),
);

export async function GET(
  context: APIContext<{ thread: CollectionEntry<"threads"> }>,
) {
  const { thread } = context.props;
  const title = `${SITE_TITLE} — ${thread.data.title}`;
  const description =
    thread.data.description ?? `Entries in the "${thread.data.title}" thread`;
  const items = await buildRSSItems(
    await allExpressions(
      (e) => e.data.threads?.some((t) => t.id === thread.id) ?? false,
    ),
  );

  return makeRSSFeed(context, title, description, items);
}
