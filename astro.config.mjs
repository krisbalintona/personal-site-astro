// @ts-check

import mdx from "@astrojs/mdx";
import { defineConfig } from "astro/config";

import typesafeRoutes from "astro-typesafe-routes";

// https://astro.build/config
export default defineConfig({
  site: "https://kristofferbalintona.me",
  prerenderConflictBehavior: "error",
  integrations: [
    mdx({
      syntaxHighlight: "shiki",
      shikiConfig: { theme: "github-light" },
      gfm: false,
    }),
    typesafeRoutes(),
  ],
});
