import rss from "@astrojs/rss";
import { allPostEntries } from "@src/lib/posts.ts";
import type { APIContext } from "astro";
import { $path } from "astro-typesafe-routes/path";

export async function GET(context: APIContext) {
  if (!context.site) {
    throw new Error("site is not set in astro.config.ts");
  }
  const postEntries = await allPostEntries();
  const postRSSItems = postEntries.map((entry) => ({
    title: entry.data.title,
    pubDate: entry.data.pubDate,
    description: entry.data.description,
    link: $path({
      to: "/articles/[slug]",
      params: { slug: entry.data.slug },
    }),
  }));

  return rss({
    site: context.site,
    title: "Kristoffer Balintona — Posts",
    description: `All posts across ${context.site}`,
    stylesheet: "/pretty-feed-v3.xsl",
    customData: "<language>en-us</language>",
    items: postRSSItems,
  });
}
