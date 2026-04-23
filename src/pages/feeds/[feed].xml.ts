import { makeRSSFeed, type RSSFeed, RSSFeeds } from "@lib/rss.ts";
import type { APIContext } from "astro";

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
    channel.items
  );
}
