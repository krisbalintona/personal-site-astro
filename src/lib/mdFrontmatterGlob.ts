import { existsSync, promises as fs } from "node:fs";
import { relative } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import type { Loader } from "astro/loaders";
import { z } from "astro/zod";
import matter from "gray-matter";
import pLimit from "p-limit";
import picomatch from "picomatch";
import slugify from "slugify";
import { glob as tinyglobby } from "tinyglobby";

// Notes on terminology:
//
// Source files - MD/MDX files scanned for frontmatter values
//   (configured via `sources`). Each unique value of `sourceField`
//   found across all source files becomes a stub entry.
//
// Content files - MD/MDX files that provide body + frontmatter for
//   entries (configured via `contentBase`/`contentPattern`). Each
//   content file is associated with an existing stub entry (by
//   matching its `name` frontmatter field or slugified filename to a
//   stub entry ID), or creates a new entry if no match is found.
//
// Stub entries - Entries created from source file frontmatter values
//   alone, with no associated content file. Their data is just `{
//   name: value }` and they have no renderable body.
//
// Content entries - Entries backed by a content file. Their data is
//   the content file's frontmatter, and their body is the content
//   file's body.

export default function (loaderOptions: {
  sources: {
    // Files whose frontmatter will be scanned
    pattern: string;
    base?: string;
  }[];
  sourceField: string; // Frontmatter field
  contentPattern: string; // Pattern for content files
  contentBase: string; // Base for content files
}): Loader {
  return {
    name: "md-frontmatter-glob-loader",
    schema: z.object({
      name: z.string(),
    }),
    load: async ({
      store,
      config,
      generateDigest,
      parseData,
      logger,
      watcher,
    }) => {
      const rootPath = fileURLToPath(config.root);
      const normalizedSources = loaderOptions.sources.map((source) => ({
        ...source,
        base: source.base ?? rootPath,
      }));
      const untouchedEntries = new Set(store.keys());
      // Track the field values each source file contributes, keyed by
      // absolute file path.  Used by the watcher to reconcile stub
      // entries when source files change.
      const sourceFileValuesMap = new Map<string, Set<string>>();
      // Track the entry ID each content file resolves to, keyed by
      // absolute file path.  Used by the watcher to look up the ID of
      // a content file without re-deriving it.
      const contentFileIdMap = new Map<string, string>();
      const limit = pLimit(10);
      // Build one picomatch matcher per source.  Used by the watcher
      // to filter change events to files that match the source
      // pattern.  We can't rely on the watcher's own globbing because
      // we watch entire base directories (not individual files) so
      // that newly created files are picked up - this means the
      // watcher fires for ALL changes under those directories, and we
      // need to filter down to only the files that match the
      // configured patterns ourselves.
      const sourceMatchers = normalizedSources.map((source) => ({
        base: source.base,
        match: picomatch(source.pattern),
      }));
      const contentMatcher = picomatch(loaderOptions.contentPattern);

      //// Process source files

      // Find relevant source files
      const filesBySource = await Promise.all(
        normalizedSources.map(async (source) => {
          if (!existsSync(source.base)) {
            logger.warn(`The base directory "${source.base}" does not exist.`);
            return [];
          }
          const files = await tinyglobby(source.pattern, {
            cwd: source.base,
            expandDirectories: false,
          });
          if (files.length === 0) {
            logger.warn(`No files found matching "${source.pattern}"`);
          }
          return files.map((file) => ({
            path: fileURLToPath(
              new URL(encodeURI(file), pathToFileURL(`${source.base}/`))
            ),
            base: source.base,
          }));
        })
      );
      const resolvedSourceFiles = [
        ...new Set(filesBySource.flat().map((sourceFile) => sourceFile.path)),
      ];

      // Scrape all desired frontmatter field values from a source file
      async function extractFieldValues(file: string): Promise<string[]> {
        const fileUrl = pathToFileURL(file);
        const contents = await fs.readFile(fileUrl, "utf-8").catch((err) => {
          logger.error(`Error reading ${file}: ${err.message}`);
          return;
        });
        if (!contents && contents !== "") {
          logger.warn(`No contents found for ${file}`);
          return [];
        }
        const { data } = matter(contents);
        const fieldValue = data[loaderOptions.sourceField];
        if (!fieldValue) {
          return [];
        }
        const values = Array.isArray(fieldValue) ? fieldValue : [fieldValue];
        // Coerce all values into strings
        return values.flatMap((v) => {
          switch (typeof v) {
            case "string":
              return [v];
            case "number":
            case "boolean":
              return [String(v)];
            default:
              logger.warn(
                `Unexpected value type "${typeof v}" for field "${loaderOptions.sourceField}" in ${file}, skipping`
              );
              return [];
          }
        });
      }

      // Store a single stub entry for a field value
      async function syncStubEntry(value: string): Promise<void> {
        const id = value;
        const digest = generateDigest(value);
        const existingEntry = store.get(id);
        if (existingEntry?.digest === digest) {
          return;
        }
        const parsedData = await parseData({ id, data: { name: value } });
        store.set({ id, data: parsedData, digest });
      }

      // Store one stub entry per unique field value
      const nestedFieldValues = await Promise.all(
        resolvedSourceFiles.map((file) =>
          limit(async () => {
            const values = await extractFieldValues(file);
            sourceFileValuesMap.set(file, new Set(values));
            return values;
          })
        )
      );
      const stubEntryIds = new Set(nestedFieldValues.flat());
      for (const value of stubEntryIds) {
        await syncStubEntry(value);
        untouchedEntries.delete(value);
      }

      //// Process content files
      // Associate content files with stub entries (by matching the
      // content file's `name` frontmatter field or slugified filename
      // to a stub entry ID), or create new content entries if no
      // match is found.

      const contentBaseUrl = new URL(
        loaderOptions.contentBase,
        pathToFileURL(`${rootPath}/`)
      );
      const contentBasePath = fileURLToPath(contentBaseUrl);
      const contentFiles = await tinyglobby(loaderOptions.contentPattern, {
        cwd: contentBasePath,
        expandDirectories: false,
      });
      if (contentFiles.length === 0) {
        logger.warn(
          `No content files found matching "${loaderOptions.contentPattern}" in "${loaderOptions.contentBase}"`
        );
      }

      // Process a single content file and update the store.  Returns
      // the resolved entry ID, or undefined if the file could not be
      // processed.  The caller is responsible for updating
      // `untouchedEntries` if relevant.
      async function syncContentEntry(
        file: string
      ): Promise<string | undefined> {
        const fileUrl = new URL(
          encodeURI(file),
          pathToFileURL(`${contentBasePath}/`)
        );
        const absPath = fileURLToPath(fileUrl);

        const contents = await fs.readFile(fileUrl, "utf-8").catch((err) => {
          logger.error(`Error reading ${file}: ${err.message}`);
          return;
        });
        if (!contents && contents !== "") {
          logger.warn(`No contents found for ${absPath}`);
          return;
        }
        const { data: frontmatter } = matter(contents);

        // Determine the entry ID: use `name` frontmatter field if
        // present (and a string), otherwise slugify the parent
        // directory name
        let id: string;
        if (frontmatter.name && typeof frontmatter.name === "string") {
          id = frontmatter.name;
        } else {
          // Use the parent directory name as the slug, since content
          // files like `foo-bar/index.mdx` may share the same
          // filename
          const dirname = file.split("/").at(-2) ?? file;
          id = slugify(dirname, { lower: true, strict: true });
        }
        contentFileIdMap.set(absPath, id);

        const digest = generateDigest(contents);
        const existingEntry = store.get(id);
        if (existingEntry?.digest === digest) {
          return id;
        }
        const parsedData = await parseData({
          id,
          // `name` is kept in the data so the schema is
          // consistent across stub entries and content entries
          data: frontmatter,
          filePath: absPath,
        });
        store.set({
          id,
          data: parsedData,
          filePath: relative(rootPath, absPath).replace(/\\/g, "/"),
          digest,
          deferredRender: true,
        });
        return id;
      }

      if (existsSync(contentBasePath)) {
        await Promise.all(
          contentFiles.map((file) =>
            limit(async () => {
              const id = await syncContentEntry(file);
              if (id) {
                untouchedEntries.delete(id);
              }
            })
          )
        );
      } else {
        logger.warn(
          `The content base directory "${contentBasePath}" does not exist.`
        );
      }

      //// Cleanup
      // Delete entries in the store from previous builds whose
      // entries are now gone
      for (const id of untouchedEntries) {
        store.delete(id);
      }

      //// Watchers (for dev server only)
      if (!watcher) {
        return;
      }
      for (const source of normalizedSources) {
        // We watch source base directories instead of
        // `resolvedSourceFiles` so we aren't constrained to the files
        // resolved on the first run
        watcher.add(source.base);
      }
      watcher.add(contentBasePath);

      //// Source file watcher handlers

      // Delete a stub entry only if no source file still references
      // its value, and only if it doesn't have an associated content
      // file (content entries have filePath set; stub entries don't)
      function deleteStubEntryMaybe(value: string) {
        const stillExists = [...sourceFileValuesMap.values()].some(
          (fileValues) => fileValues.has(value)
        );
        if (!stillExists) {
          const entry = store.get(value);
          if (!entry?.filePath) {
            store.delete(value);
          }
        }
      }

      async function onSourceChangeOrAdd(absPath: string) {
        try {
          const newValues = new Set(await extractFieldValues(absPath));
          const oldValues = sourceFileValuesMap.get(absPath) ?? new Set();
          sourceFileValuesMap.set(absPath, newValues);
          logger.info(`Reloaded data from ${relative(rootPath, absPath)}`);
          // Add stub entries for new values
          for (const value of newValues) {
            stubEntryIds.add(value);
            if (!store.has(value)) {
              await syncStubEntry(value);
            }
          }
          // Remove stub entries for values no longer in any source
          // file
          for (const value of oldValues) {
            stubEntryIds.delete(value);
            deleteStubEntryMaybe(value);
          }
        } catch (e) {
          logger.error(
            `Failed to reload ${relative(rootPath, absPath)}: ${(e as Error).message}`
          );
        }
      }

      function onSourceUnlink(absPath: string) {
        const oldValues = sourceFileValuesMap.get(absPath);
        if (!oldValues) {
          return;
        }
        sourceFileValuesMap.delete(absPath);
        logger.info(`Removed source file ${relative(rootPath, absPath)}`);
        for (const value of oldValues) {
          stubEntryIds.delete(value);
          deleteStubEntryMaybe(value);
        }
      }

      //// Content file watcher handlers

      async function onContentChangeOrAdd(absPath: string) {
        // Convert absolute path back to the relative form that
        // syncContentEntry expects (relative to contentBasePath,
        // posix-style)
        try {
          await syncContentEntry(
            relative(contentBasePath, absPath).replace(/\\/g, "/")
          );
          logger.info(`Reloaded data from ${relative(rootPath, absPath)}`);
        } catch (e) {
          logger.error(
            `Failed to reload ${relative(rootPath, absPath)}: ${(e as Error).message}`
          );
        }
      }

      async function onContentUnlink(absPath: string) {
        const id = contentFileIdMap.get(absPath);
        if (!id) {
          return;
        }
        try {
          contentFileIdMap.delete(absPath);
          logger.info(`Removed entry for ${relative(rootPath, absPath)}`);
          if (stubEntryIds.has(id)) {
            // Revert to a stub entry rather than deleting outright
            await syncStubEntry(id);
          } else {
            store.delete(id);
          }
        } catch (e) {
          logger.error(
            `Failed to remove entry for ${relative(rootPath, absPath)}: ${(e as Error).message}`
          );
        }
      }

      //// Route watcher events to the correct handler
      watcher.on("change", (absPath) => {
        if (absPath.startsWith(contentBasePath)) {
          if (
            contentMatcher(
              relative(contentBasePath, absPath).replace(/\\/g, "/")
            )
          ) {
            onContentChangeOrAdd(absPath);
          }
        } else {
          const matchingSource = sourceMatchers.find(({ base, match }) =>
            match(relative(base, absPath).replace(/\\/g, "/"))
          );
          if (matchingSource) {
            onSourceChangeOrAdd(absPath);
          }
        }
      });
      watcher.on("add", (absPath) => {
        if (absPath.startsWith(contentBasePath)) {
          if (
            contentMatcher(
              relative(contentBasePath, absPath).replace(/\\/g, "/")
            )
          ) {
            onContentChangeOrAdd(absPath);
          }
        } else {
          const matchingSource = sourceMatchers.find(({ base, match }) =>
            match(relative(base, absPath).replace(/\\/g, "/"))
          );
          if (matchingSource) {
            onSourceChangeOrAdd(absPath);
          }
        }
      });
      watcher.on("unlink", (absPath) => {
        if (absPath.startsWith(contentBasePath)) {
          if (
            contentMatcher(
              relative(contentBasePath, absPath).replace(/\\/g, "/")
            )
          ) {
            onContentUnlink(absPath);
          }
        } else {
          const matchingSource = sourceMatchers.find(({ base, match }) =>
            match(relative(base, absPath).replace(/\\/g, "/"))
          );
          if (matchingSource) {
            onSourceUnlink(absPath);
          }
        }
      });
    },
  } satisfies Loader;
}
