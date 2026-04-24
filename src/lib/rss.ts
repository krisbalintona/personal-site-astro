import { render } from "astro:content";
import mdxRenderer from "@astrojs/mdx/server.js";
import generateRssFeed, { type RSSFeedItem } from "@astrojs/rss";
import { SITE_TITLE, SITE_URL } from "@lib/consts.ts";
import { allPostEntries } from "@lib/posts.ts";
import type { APIContext } from "astro";
import { experimental_AstroContainer } from "astro/container";
import { $path } from "astro-typesafe-routes/path";
import sanitize from "sanitize-html";

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

export const rssArticleItems: RSSFeedItem[] = await Promise.all(
  (await allPostEntries()).map(async (entry) => {
    const { Content } = await render(entry);
    const rawHTML: string = await container.renderToString(Content);

    // Sanitize rendered content to HTML suitable for an RSS feed
    // reader.
    //
    // The method below is a variant of the one found here:
    // https://github.com/delucis/astro-blog-full-text-rss/blob/latest/src/pages/rss.xml.ts,
    // which was pointed to by
    // https://docs.astro.build/en/recipes/rss/#including-full-post-content.
    // The difference is that we use the sanitize-html library to more
    // thoroughly strip elements and classes; the documentation linked
    // above shows a rudimentary usage of the library for this
    // purpose.
    //
    // Using sanitize-html is more appropriate since Expressive Code
    // (EC) and its plugins may introduce undesirable elements such as
    // buttons.  Using sanitize-html also brings forward compatibility
    // for any other elements I may introduce into my rendered entry
    // content in the future.
    //
    // Below does the following:
    // - Strips all elements not in the allowlist (including EC's copy
    //   buttons, fullscreen toggles, SVG icons, and wrapper divs),
    //   leaving code blocks as plain `<pre><code>`
    // - Makes link `href` and image `src` attributes absolute instead
    //   of relative, so they resolve correctly in feed readers that
    //   have no knowledge of the site's base URL
    // - Strips any `<script>` and `<style>` tags (covered implicitly
    //   by sanitize-html's allowlist, since neither is a permitted
    //   tag)
    const renderedHTML: string = sanitize(rawHTML, {
      // Preserve `img`s in feed content
      allowedTags: sanitize.defaults.allowedTags.concat(["img"]),
      // Convert site-relative hrefs to absolute URLs
      transformTags: {
        a: (tagName, attribs) => ({
          tagName,
          attribs: {
            ...attribs,
            ...(attribs.href && {
              href: attribs.href.startsWith("/")
                ? SITE_URL + attribs.href
                : attribs.href,
            }),
          },
        }),
        img: (tagName, attribs) => ({
          tagName,
          attribs: {
            ...attribs,
            src: attribs.src?.startsWith("/")
              ? SITE_URL + attribs.src
              : attribs.src,
          },
        }),
      },
    });

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
        to: "/posts/[postid]",
        params: { postid: entry.id },
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
