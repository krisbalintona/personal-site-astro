// @ts-check

import mdx from "@astrojs/mdx";
import sitemap from "@astrojs/sitemap";
import { defineConfig, fontProviders } from "astro/config";
import astroBrokenLinksChecker from "astro-broken-links-checker";
import astroD2 from "astro-d2";
import expressiveCode from "astro-expressive-code";
import typesafeRoutes from "astro-typesafe-routes";
import { pluginFullscreen } from "expressive-code-fullscreen";
import { SITE_URL } from "./src/lib/consts.ts";
import { faviconRss } from "./src/lib/faviconRss.ts";

import icon from "astro-icon";

// https://astro.build/config
export default defineConfig({
  site: SITE_URL,
  trailingSlash: "always",
  prerenderConflictBehavior: "error",
  integrations: [
    faviconRss(),
    typesafeRoutes(),
    expressiveCode({
      themes: ["material-theme-lighter", "material-theme-darker"],
      useDarkModeMediaQuery: true,
      plugins: [pluginFullscreen()],
      styleOverrides: {
        codeFontFamily: "var(--font-code)",
        codeFontSize: "var(--font-step--1)",
        codeBackground: "var(--color-bg-elevated)",
        borderColor: "var(--color-border)",
        fullscreen: {
          // Toolbar uses --color-text instead of neutral gray to feel
          // intentional on a warm site
          toolbarBg: "color-mix(in srgb, var(--color-text) 95%, transparent)",
          toolbarBorder:
            "color-mix(in srgb, var(--color-text) 15%, transparent)",

          // Button styling
          buttonBgHover:
            "color-mix(in srgb, var(--color-text) 30%, transparent)",
          buttonBgActive:
            "color-mix(in srgb, var(--color-text) 95%, transparent)",
          buttonText: "var(--color-bg)", // warmer than pure white
          buttonBorder:
            "color-mix(in srgb, var(--color-text-muted) 25%, transparent)",
          buttonFocus:
            "color-mix(in srgb, var(--color-accent) 50%, transparent)", // --color-accent for focus rings

          // --color-text instead of neutral black keeps shadows warm
          contentShadow:
            "color-mix(in srgb, var(--color-text) 40%, transparent)",

          // Hints use --color-text + --color-bg for text to stay
          // on-palette
          hintBg: "color-mix(in srgb, var(--color-text) 97%, transparent)",
          hintText: "var(--color-bg)",
          hintBorder:
            "color-mix(in srgb, var(--color-text-muted) 20%, transparent)",
        },
      },
    }),
    astroD2({ experimental: { useD2js: true } }),
    mdx({ gfm: false }),
    astroBrokenLinksChecker({
      checkExternalLinks: false,
    }),
    sitemap({ filter: (page) => !page.startsWith(`${SITE_URL}/posts/`) }),
    icon(),
  ],
  fonts: [
    {
      // Other good choices:
      // Source Serif 4
      name: "Lora",
      cssVariable: "--font-primary",
      provider: fontProviders.fontsource(),
      fallbacks: ["Georgia", "serif"],
    },
    {
      // Other good choices (almost all "humanist sans serif"):
      // Jost
      // Nunito
      // Alegreya Sans
      // Source Sans 3
      // Fira Sans
      name: "Source Sans 3",
      cssVariable: "--font-ui",
      provider: fontProviders.fontsource(),
      fallbacks: ["sans-serif"],
    },
    {
      name: "Iosevka Charon Mono",
      cssVariable: "--font-code",
      provider: fontProviders.fontsource(),
      fallbacks: ["Consolas", "Liberation Mono", "Courier New", "monospace"],
    },
  ],
  vite: {
    css: {
      preprocessorOptions: {
        scss: {
          loadPaths: ["./src/styles/"],
        },
      },
    },
  },
});
