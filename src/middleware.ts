import { defineMiddleware, sequence } from "astro:middleware";

import { onRequest as staticHeaders } from "../node_modules/astro-static-headers/dist/middleware.js";

// Tell TypeScript that this global may exist on globalThis.
// astro-static-headers sets it up during `astro build` to collect
// headers/redirects as each static page is rendered, but it's never
// initialized in `astro dev`.
declare global {
  var __astroStaticHeaders:
    | {
        routes: Record<string, string[]>;
        redirects: Record<string, unknown>;
        headers: Record<string, Headers>;
      }
    | undefined;
}

// If the global isn't already set (i.e., we're in dev), initialize it
// with empty collections so astro-static-headers doesn't crash when
// it tries to read from it.  In production the build process sets
// this up before any middleware runs, so ??= is a no-op there.
const fixStaticHeaders = defineMiddleware((_, next) => {
  globalThis.__astroStaticHeaders ??= {
    routes: {},
    redirects: {},
    headers: {},
  };
  return next();
});

// Run our fix first, then the real astro-static-headers middleware.
export const onRequest = sequence(fixStaticHeaders, staticHeaders);
