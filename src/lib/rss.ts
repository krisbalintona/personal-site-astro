import generateRssFeed, { type RSSFeedItem } from "@astrojs/rss";
import { allPostEntries } from "@lib/posts.ts";
import type { APIContext } from "astro";
import { $path } from "astro-typesafe-routes/path";

const sharedConfig = {
  stylesheet: "/pretty-feed-v3.xsl",
  customData: "<language>en-us</language>",
};

export function makeRSSFeed(
  context: APIContext,
  title: string,
  description: string,
  items: RSSFeedItem[]
) {
  if (!context.site) {
    throw new Error("site is not set in astro.config.ts");
  }

  return generateRssFeed({
    ...sharedConfig,
    site: context.site,
    title,
    description,
    items,
  });
}

export const rssArticleItems = (await allPostEntries()).map((entry) => ({
  title: entry.data.title,
  pubDate: entry.data.pubDate,
  description: entry.data.description,
  link: $path({
    to: "/articles/[slug]",
    params: { slug: entry.data.slug },
  }),
}));
