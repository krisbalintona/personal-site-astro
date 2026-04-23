import type { RSSFeedItem } from "@astrojs/rss";
import { makeRSSFeed, rssArticleItems } from "@lib/rss.ts";
import type { APIContext } from "astro";

interface RSSFeed {
  description: string;
  items: RSSFeedItem[];
  title: string;
}

const feeds: Record<string, RSSFeed> = {
  all: {
    title: "Kristoffer Balintona — All",
    description: "All posts",
    items: rssArticleItems,
  },
  articles: {
    title: "Kristoffer Balintona — Articles",
    description: "Essays and long-form writing",
    items: rssArticleItems,
  },
};

export function getStaticPaths() {
  return Object.entries(feeds).map(([feedName, channel]) => ({
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
