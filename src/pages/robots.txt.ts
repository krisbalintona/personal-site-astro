import type { APIRoute } from "astro";

const getRobotsTxt = (sitemapURL: URL) => `\
User-agent: *
Allow: /

Sitemap: ${sitemapURL.href}
`;

// Dynamically generate a robots.txt file.  Taken from
// https://docs.astro.build/en/guides/integrations-guide/sitemap/#sitemap-link-in-robotstxt
export const GET: APIRoute = ({ site }) => {
  const sitemapURL = new URL("sitemap-index.xml", site);
  return new Response(getRobotsTxt(sitemapURL));
};
