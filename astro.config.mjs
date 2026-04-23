// @ts-check

import mdx from "@astrojs/mdx";
import { defineConfig, fontProviders } from "astro/config";
import expressiveCode from "astro-expressive-code";
import typesafeRoutes from "astro-typesafe-routes";

// https://astro.build/config
export default defineConfig({
  site: "https://kristofferbalintona.me",
  prerenderConflictBehavior: "error",
  integrations: [
    expressiveCode({
      themes: ["material-theme-lighter"],
    }),
    mdx({ gfm: false }),
    typesafeRoutes(),
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
