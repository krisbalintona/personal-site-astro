import { getEntryUrl } from "@lib/entries";
import { allExpressions, getExpressionStableId } from "@lib/expressions.ts";
import type { APIContext } from "astro";
import { createRoute } from "astro-typesafe-routes/create-route";

export const Route = createRoute({
  routeId: "/posts/[stableId]",
});

export const prerender = false;

const expressions = allExpressions();

export const GET = async ({ params, redirect }: APIContext) => {
  const resolved = await expressions;
  const expression = resolved.find(
    (e) => getExpressionStableId(e) === params.stableId,
  );

  if (!expression) {
    return redirect("/404", 302);
  } else {
    return redirect(getEntryUrl(expression), 301);
  }
};
