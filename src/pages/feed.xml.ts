import { makeRSSFeed, RSSFeeds } from "@lib/rss.ts";
import type { APIContext } from "astro";
import { createRoute } from "astro-typesafe-routes/create-route";

export const Route = createRoute({
  routeId: "/feed.xml",
});

export function GET(context: APIContext) {
  const channel = RSSFeeds["All"];

  return makeRSSFeed(
    context,
    channel.title,
    channel.description,
    channel.items,
  );
}
