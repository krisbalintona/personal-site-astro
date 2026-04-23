import { getCollection } from "astro:content";
import type { PostEntry } from "@lib/posts.ts";
import type { APIContext } from "astro";
import { type AstroAny, createRoute } from "astro-typesafe-routes/create-route";

export const Route = createRoute({
  routeId: "/posts/[postid]",
});

export const getStaticPaths = Route.createGetStaticPaths(async () => {
  // Currently, only posts that aren't drafts get a permalink
  const allPosts = (
    await Promise.all([
      getCollection("articles", (entry) => entry.data.draft === false),
    ])
  ).flat();

  return allPosts.map((post) => ({
    params: { postid: post.id },
    props: { post },
  }));
});

export function GET(context: APIContext<{ post: PostEntry }>) {
  const { post } = context.props;

  return Route.redirect(context as AstroAny, {
    to: `/${post.collection}/[slug]`,
    params: { slug: post.data.slug },
  });
}
