import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { load } from "cheerio";
import { codeToHtml } from "shiki";

// ==============================
// Code highlighting
// ==============================
//
// Use Shiki to highlight code blocks.  See the Shiki documentation
// for more information: https://shiki.style/guide/install.

/**
 * Highlights an HTML string and returns an HTML string with code
 * blocks within highlighted using Shiki.  The highlighted code blocks
 * are those matching the query "pre.src > code", which matches the
 * HTML structure produced by Org mode's HTML export.
 *
 * @param html - Raw HTML string
 * @param postId - Post Id, used for logging/debugging
 * @returns HTML string with code blocks highlighted
 */
async function highlightCode(html: string, postId: string): Promise<string> {
  // Org exports code blocks inside a div whose class is
  // "org-src-container," which contains a code element wrapped in a
  // pre tag whose classes are "src" and "src-LANG"
  const $ = load(html, null, false); // Don't introduce wrapping elements

  // `codeToHtml` is async but Cheerio's `each` method isn't, so we
  // have to iterate using a for loop
  const codeBlocks = $("pre.src > code");
  // console.log(`[${postId}] Number of code blocks found:`, codeBlocks.length);
  for (const el of codeBlocks.toArray()) {
    // Cheerio collections aren't iterable, so we turn it into an
    // array of DOM objects, then convert those DOM objects back into
    // Cheerio objects
    const $code = $(el);
    // console.log(`[${postId}] code element:`, $code); // Debug
    const $pre = $code.parent();

    const lang = $pre
      .attr("class")
      ?.split(" ")
      .find((c) => c.startsWith("src-"))
      ?.slice("src-".length);
    // console.log(`[${postId}] lang:`, lang); // Debug
    if (!lang) {
      console.warn(
        `[${postId}] pre.src has no language class! Not highlighting code`
      );
      continue;
    }
    const text = $code.text();
    // console.log("Text being passed to highlighter:", text);

    // `codeToHtml` returns a code element wrapped in a pre tag.  So
    // we have to replace the pre element, not the code element.
    $pre.replaceWith(
      await codeToHtml(text, {
        lang,
        theme: "github-light",
      })
    );
  }

  return $.html();
}

// ==============================
// Posts
// ==============================
//
// Posts directory structure:
//
// 1. Posts are located in subdirectories under src/lib/posts/.
// 2. Subdirectory names are of the form POSTID--POSTSLUG.
// 3. Each post subdirectory has (i) an index.html that is the HTML
//    body of the post and (ii) a metadata.json that contains metadata
//    about the post itself.
// 4. Assets are contained in the assets subdirectory of each post
//    subdirectory.

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const POSTS_DIR = path.resolve(__dirname, "posts/");

interface PostMetadata {
  date: string;
  postId: string;
  slug: string;
  title: string;
}

export interface Post extends PostMetadata {
  content: string;
}

/**
 * Serialize post.
 *
 * @param subdirName - Name of subdirectory under src/lib/posts/
 * @returns Object containing `postId`, `title`, `slug`, `date`, and
 *   `content`
 */
async function serializePost(subdirName: string): Promise<Post> {
  const postPath = path.join(POSTS_DIR, subdirName);

  // Metadata
  const metadata: PostMetadata = JSON.parse(
    fs.readFileSync(path.join(postPath, "metadata.json"), "utf-8")
  );
  const postId = metadata.postId;
  if (!postId) {
    throw new Error(`Post ID not found: ${JSON.stringify(metadata)}`);
  }
  // console.log(`Post metadata: ${JSON.stringify(metadata)}`); // Debug

  // Content
  const rawContent = fs.readFileSync(
    path.join(postPath, "index.html"),
    "utf-8"
  );
  const content = await highlightCode(rawContent, postId);

  // Return an object literal combining metadata and content
  return {
    postId,
    title: metadata.title,
    slug: metadata.slug,
    date: metadata.date,
    content,
  };
}

/**
 * Reads all posts from `POSTS_DIR` and returns them as a list of
 * objects.  Each object contains the post's metadata and highlighted
 * HTML content.
 *
 * @returns A list of objects, each returned by `serializePost`
 */
function getPosts(): Promise<Post[]> {
  const posts_subdirs = fs
    .readdirSync(POSTS_DIR, { withFileTypes: true })
    .filter((dirent) => dirent.isDirectory())
    .map((dirent) => dirent.name);

  return Promise.all(posts_subdirs.map(serializePost));
}

export const posts: Post[] = await getPosts();
