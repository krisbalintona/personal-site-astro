import { makeRSSFeed, RSSFeeds } from "@lib/rss.ts";
import type { APIContext } from "astro";
import { createRoute } from "astro-typesafe-routes/create-route";

export const Route = createRoute({
  routeId: "/notes/feed.xml",
});

const feeds = await RSSFeeds();

export async function GET(context: APIContext) {
  const channel = feeds["Notes"];

  return makeRSSFeed(
    context,
    channel.title,
    channel.description,
    channel.items,
  );
}
