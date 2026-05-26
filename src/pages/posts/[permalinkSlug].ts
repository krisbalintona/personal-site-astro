import { getEntryUrl } from "@lib/entries";
import { allExpressions } from "@lib/expressions.ts";
import type { APIContext } from "astro";
import { createRoute } from "astro-typesafe-routes/create-route";

export const Route = createRoute({
  routeId: "/posts/[permalinkSlug]",
});

export const prerender = false;

const expressions = allExpressions();

export const GET = async ({ params, redirect }: APIContext) => {
  const resolved = await expressions;
  const expression = resolved.find(
    (e) => e.data.permalinkSlug === params.permalinkSlug,
  );

  if (!expression) {
    return redirect("/404", 302);
  } else {
    return redirect(getEntryUrl(expression), 301);
  }
};
