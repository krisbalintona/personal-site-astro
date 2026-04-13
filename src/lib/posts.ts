import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse } from "node-html-parser";
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
async function highlightCode(html: string, postId: string) {
  const dom = parse(html);
  const codeBlocks = dom.querySelectorAll("pre.src > code");
  // console.log(`[${postId}] Number of code blocks found:`, codeBlocks.length);

  // Org exports code blocks inside a div whose class is
  // "org-src-container," which contains a code element wrapped in a
  // pre tag whose classes are "src" and "src-LANG"
  for (const code of codeBlocks) {
    // console.log(`[${postId}] code element:`, code); // Debug
    const pre = code.parentNode;

    const lang = pre.classNames
      .split(" ")
      .find((c) => c.startsWith("src-"))
      ?.slice("src-".length);
    // console.log(`[${postId}] lang:`, lang); // Debug
    if (!lang) {
      console.warn(`[${postId}] pre.src has no language class!`);
      continue;
    }

    const text = code.rawText;
    // console.log("Text being passed to highlighter:", text);
    //
    // Shiki's `codeToHtml` returns a code element wrapped in a pre
    // tag.  So we have to replace the pre element, not the code
    // element.
    pre.replaceWith(
      await codeToHtml(text, {
        lang,
        theme: "github-light",
      })
    );
  }
  return dom.toString();
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

/**
 * Serialize post.
 *
 * @param subdirName - Name of subdirectory under src/lib/posts/
 * @returns Object containing `postId`, `title`, `slug`, `date`, and
 *   `content`
 */
function serializePost(subdirName: string) {
  const postPath = path.join(POSTS_DIR, subdirName);
  const metadata = JSON.parse(
    fs.readFileSync(path.join(postPath, "metadata.json"), "utf-8")
  );
  const postId = metadata.postId;
  const rawContent = fs.readFileSync(
    path.join(postPath, "index.html"),
    "utf-8"
  );
  const content = highlightCode(rawContent, postId);

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
export function getPosts() {
  const posts_subdirs = fs
    .readdirSync(POSTS_DIR, { withFileTypes: true })
    .filter((dirent) => dirent.isDirectory())
    .map((dirent) => dirent.name);

  return posts_subdirs.map(serializePost);
}
