import type { ExpressionEntry } from "@lib/expressions.ts";
import type { APIContext } from "astro";
import { getCollection } from "astro:content";
import { createRoute } from "astro-typesafe-routes/create-route";
import { $path } from "astro-typesafe-routes/path";

export const Route = createRoute({
  routeId: "/posts/[permalinkSlug]",
});

export const getStaticPaths = Route.createGetStaticPaths(async () => {
  const allPosts = (await Promise.all([getCollection("articles")])).flat();

  return allPosts.map((post) => ({
    params: { permalinkSlug: post.data.permalinkSlug },
    props: { post },
  }));
});

export const GET = ({
  props,
  redirect,
}: APIContext<{ post: ExpressionEntry }>) => {
  const { post } = props;

  return redirect(
    $path({
      to: `/${post.collection}/[titleSlug]`,
      params: { titleSlug: post.data.titleSlug },
    }),
    301,
  );
};
