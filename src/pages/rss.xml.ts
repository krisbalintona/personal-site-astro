import type { APIRoute } from "astro";
import { $path } from "astro-typesafe-routes/path";

export const GET: APIRoute = ({ redirect }) => {
  return redirect(
    $path({ to: "/feeds/[feed].xml", params: { feed: "all" } }),
    301
  );
};
