import { fileURLToPath } from "url";
import path from "path";
import fs from "fs";

const __dirname = fileURLToPath(new URL(".", import.meta.url));

// Posts directory structure:
//
// 1. Posts are located in subdirectories under src/lib/posts/.
// 2. Subdirectory names are of the form POSTID--POSTSLUG.
// 3. Each post subdirectory has (i) an index.html that is the HTML
//    body of the post and (ii) a metadata.json that contains metadata
//    about the post itself.
// 4. Assets are contained in the assets subdirectory of each post subdirectory.

const POSTS_DIR = path.resolve(__dirname, "posts/");

function serializePost(subdirName: string) {
  const postPath = path.join(POSTS_DIR, subdirName);
  const metadata = JSON.parse(
    fs.readFileSync(path.join(postPath, "metadata.json"), "utf-8"),
  );
  const content = fs.readFileSync(path.join(postPath, "index.html"), "utf-8");

  return {
    postid: metadata.postId,
    title: metadata.title,
    slug: metadata.slug,
    date: metadata.date,
    content,
  };
}

export function getPosts() {
  const posts_subdirs = fs
    .readdirSync(POSTS_DIR, { withFileTypes: true })
    .filter((dirent) => dirent.isDirectory())
    .map((dirent) => dirent.name);

  return posts_subdirs.map(serializePost);
}
