// @ts-check

import markdoc from "@astrojs/markdoc";
import sitemap from "@astrojs/sitemap";
import { defineConfig, fontProviders } from "astro/config";
import astroBrokenLinksChecker from "astro-broken-links-checker";
import d2 from "astro-d2";
import expressiveCode from "astro-expressive-code";
import typesafeRoutes from "astro-typesafe-routes";
import { pluginFullscreen } from "expressive-code-fullscreen";
import { SITE_URL } from "./src/lib/consts.ts";
import { faviconRss } from "./src/lib/faviconRss.ts";

// https://astro.build/config
export default defineConfig({
  site: SITE_URL,
  prerenderConflictBehavior: "error",
  integrations: [
    expressiveCode({
      themes: ["material-theme-lighter"],
      plugins: [pluginFullscreen()],
      styleOverrides: {
        fullscreen: {
          // Toolbar uses --ink instead of neutral gray to feel
          // intentional on a warm site
          toolbarBg: "color-mix(in srgb, var(--ink) 95%, transparent)",
          toolbarBorder: "color-mix(in srgb, var(--ink) 15%, transparent)",

          // Button styling
          buttonBgHover: "color-mix(in srgb, var(--muted) 30%, transparent)",
          buttonBgActive: "color-mix(in srgb, var(--black) 95%, transparent)",
          buttonText: "var(--background)", // warmer than pure white
          buttonBorder: "color-mix(in srgb, var(--faint) 25%, transparent)",
          buttonFocus: "color-mix(in srgb, var(--accent) 50%, transparent)", // --accent for focus rings

          // --black instead of neutral black keeps shadows warm
          contentShadow: "color-mix(in srgb, var(--black) 40%, transparent)",

          // Hints use --ink + --background for text to stay
          // on-palette
          hintBg: "color-mix(in srgb, var(--ink) 97%, transparent)",
          hintText: "var(--background)",
          hintBorder: "color-mix(in srgb, var(--faint) 20%, transparent)",
        },
      },
    }),
    typesafeRoutes(),
    sitemap({ filter: (page) => !page.startsWith(`${SITE_URL}/posts/`) }),
    faviconRss(),
    d2({ experimental: { useD2js: true } }),
    markdoc(),
    astroBrokenLinksChecker({
      checkExternalLinks: false,
    }),
  ],
  fonts: [
    {
      name: "Libre Baskerville",
      cssVariable: "--font-primary",
      provider: fontProviders.fontsource(),
      fallbacks: ["Georgia", "serif"],
    },
    {
      name: "Instrument Sans",
      cssVariable: "--font-ui",
      provider: fontProviders.fontsource(),
      fallbacks: ["sans-serif"],
    },
  ],
});
