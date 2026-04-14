// @ts-check

import mdx from "@astrojs/mdx";
import { defineConfig } from "astro/config";

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
  ],
});
