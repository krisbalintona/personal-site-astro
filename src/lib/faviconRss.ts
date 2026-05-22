import { existsSync } from "node:fs";

import type { AstroIntegration } from "astro";
import sharp from "sharp";

export function faviconRss(): AstroIntegration {
  return {
    name: "favicon-rss",
    hooks: {
      "astro:build:start": async () => {
        const source = existsSync("public/favicon.png")
          ? "public/favicon.png"
          : "public/favicon.svg";
        await sharp(source)
          .resize(88, 88, {
            fit: "contain",
            background: { r: 0, g: 0, b: 0, alpha: 0 },
          })
          .png()
          .toFile("public/favicon-rss.png");
      },
    },
  };
}
