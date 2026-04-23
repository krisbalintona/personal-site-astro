import { render } from "astro:content";
import mdxRenderer from "@astrojs/mdx/server.js";
import generateRssFeed, { type RSSFeedItem } from "@astrojs/rss";
import { SITE_TITLE, SITE_URL } from "@lib/consts.ts";
import { allPostEntries } from "@lib/posts.ts";
import type { APIContext } from "astro";
import { experimental_AstroContainer } from "astro/container";
import { $path } from "astro-typesafe-routes/path";
import { transform, walk } from "ultrahtml";
import sanitize from "ultrahtml/transformers/sanitize";

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

// Create a container to return rendered HTML as a string
const container = await experimental_AstroContainer.create();
container.addServerRenderer({ renderer: mdxRenderer });

const DOCTYPE_REGEX = /^<!DOCTYPE html>/;

export const rssArticleItems: RSSFeedItem[] = await Promise.all(
  (await allPostEntries()).map(async (entry) => {
    const { Content } = await render(entry);
    const rawHTML: string = await container.renderToString(Content);

    // Process and sanitize the raw content.  Taken from
    // https://github.com/delucis/astro-blog-full-text-rss/blob/latest/src/pages/rss.xml.ts
    // as pointed to by
    // https://docs.astro.build/en/recipes/rss/#including-full-post-content,
    // which also describes what is necessary to consider in HTML
    // contained in RSS feeds
    //
    // It does the following:
    // - Removes `<!DOCTYPE html>` preamble
    // - Makes link `href` and image `src` attributes absolute instead
    //   of relative
    // - Strips any `<script>` and `<style>` tags
    const renderedHTML: string = await transform(
      rawHTML.replace(DOCTYPE_REGEX, ""),
      [
        async (node) => {
          await walk(node, (node) => {
            if (node.name === "a" && node.attributes.href?.startsWith("/")) {
              node.attributes.href = SITE_URL + node.attributes.href;
            }
            if (node.name === "img" && node.attributes.src?.startsWith("/")) {
              node.attributes.src = SITE_URL + node.attributes.src;
            }
          });
          return node;
        },
        sanitize({ dropElements: ["script", "style"] }),
      ]
    );

    // See
    // https://github.com/withastro/astro/tree/main/packages/astro-rss:
    // rendered HTML should either (i) be in the description if there
    // is no actual description or (ii) be in a content element if
    // there is an actual entry description, with that description
    // being in the description element
    const hasDescription: boolean = !!entry.data.description;
    const description = hasDescription ? entry.data.description : renderedHTML;
    const content = hasDescription ? renderedHTML : undefined;

    return {
      title: entry.data.title,
      pubDate: entry.data.pubDate,
      link: $path({
        to: "/articles/[slug]",
        params: { slug: entry.data.slug },
      }),
      description,
      content,
    };
  })
);

export interface RSSFeed {
  description: string;
  items: RSSFeedItem[];
  title: string;
}

export const RSSFeeds: Record<string, RSSFeed> = {
  all: {
    title: `${SITE_TITLE} — All`,
    description: "All posts",
    items: rssArticleItems,
  },
  articles: {
    title: `${SITE_TITLE} — Articles`,
    description: "Essays and long-form writing",
    items: rssArticleItems,
  },
};
