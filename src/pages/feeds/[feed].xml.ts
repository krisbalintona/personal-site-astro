import { makeRSSFeed, type RSSFeed, RSSFeeds } from "@lib/rss.ts";
import type { APIContext } from "astro";
import { createRoute } from "astro-typesafe-routes/create-route";

export const Route = createRoute({
  routeId: "/feeds/[feed].xml",
});

export function getStaticPaths() {
  return Object.entries(RSSFeeds).map(([feedName, channel]) => ({
    params: { feed: feedName },
    props: { channel },
  }));
}

export function GET(context: APIContext<{ channel: RSSFeed }>) {
  const { channel } = context.props;

  return makeRSSFeed(
    context,
    channel.title,
    channel.description,
    channel.items,
  );
}
