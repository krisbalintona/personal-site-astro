;;; ox-mdx.el --- Astro MDX Org-mode exporter -*- lexical-binding: t -*-

;; Copyright (C) 2026 Kristoffer Balintona

;; Author: Kristoffer Balintona
;; Created: 2026

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Export from Org-mode to MDX.  This file defines the org export
;; backend and integrates with org-publish.  The export backend is
;; derived from ox-md's markdown backend, with various tweaks tailored
;; to this site's needs and features.

;;; Code:
(require 'ox)
(require 'ox-md)
(require 'ox-publish)
(require 'el-patch)

;;;; Variables and options

(defcustom org-mdx-root-dir (project-root (project-current))
  "Root directory of project.
This option is used to define the value of other relevant paths."
  :type 'directory
  :group 'org-mdx)

(defcustom org-mdx-posts-dir (expand-file-name "src/lib/posts/" org-mdx-root-dir)
  "Directory where posts will be exported to."
  :type 'directory
  :group 'org-mdx)

;;;; Backend

;;;;; Functions

(defun org-mdx--escape-special-chars (string)
  "Escape characters in STRING with special significance in MDX.
This includes the following characters:
- &
- <
- >
- {
- }"
  ;; Escape characters that would be mistaken from JSX expression
  ;; syntax
  (thread-last string
               (replace-regexp-in-string "&" "&amp;")
               (replace-regexp-in-string "<" "&lt;")
               (replace-regexp-in-string ">" "&gt;")
               (replace-regexp-in-string "{" "&#123;")
               (replace-regexp-in-string "}" "&#125;")))

(defun org-mdx-plain-text (text info)
  "Transcode a TEXT string into MDX-safe plain text.
Escapes constructs that are valid in Markdown but invalid in MDX's JSX
parser, then applies `org-md-plain-text'.

TEXT is the string to transcode.  INFO is a plist holding information
for the export process."
  ;; Do the default, `org-md-plain-text', after
  ;; `org-mdx--escape-special-chars' since it may introduce characters
  ;; that should not be escaped yet would be replaced above if called
  ;; first.  And it is safe to go last since it doesn't modify any of
  ;; the replacements above.
  (org-md-plain-text (org-mdx--escape-special-chars text) info))

(defun org-mdx-example-block (example-block contents info)
  "Transcode EXAMPLE-BLOCK element into MDX format.
Wrap in a fenced code block.

EXAMPLE-BLOCK is org element example block.  CONTENTS is always nil for
example blocks.  INFO is a plist holding information for the export
process."
  (let ((block-text (string-trim-right
                     (org-remove-indentation
                      (org-export-format-code-default example-block info)))))
    (format "```\n%s\n```" block-text)))

(defun org-mdx-src-block (src-block _contents info)
  "Transcode a SRC-BLOCK element from Org to a markdown fenced code block.
SRC-BLOCK is org element src block.  CONTENTS is always nil for src
blocks.  INFO is a plist holding information for the export process.

Return the src block as CommonMark fenced code block.  For example, the
following Org source block:

    #+BEGIN_SRC python
    def greet(name):
        return f\"Hello, {name}!\"

    print(greet(\"World\"))
    #+END_SRC

will return:

    \\=`\\=`\\=`python
    def greet(name):
        return f\"Hello, {name}!\"

    print(greet(\"World\"))
    \\=`\\=`\\=`"
  (let ((lang (org-element-property :language src-block))
        (inner (org-remove-indentation
                (org-export-format-code-default src-block info))))
    (format "```%s\n%s\n```" lang (string-trim inner))))

;; TODO 2026-04-16: For now we do this.  But this should be the place
;; where I add support for e.g. alerts.  In such cases, it should be
;; wrapped by component tags and that component should be imported if
;; not already.  (Perhaps the component should just be the special
;; block name, with normalized capitalization.  If the component
;; doesn't exist, then Astro will error; we fix it at that level
;; rather than checking in Elisp, somehow, whether that component
;; exists.)
(defun org-mdx-special-block (_special-block contents info)
  "Transcode _SPECIAL-BLOCK element into MDX format.
Wrap CONTENTS in a `div' tag.  Preserve newline characters when
rendering CONTENTS.

_SPECIAL-BLOCK is a special block org element.  CONTENTS is the
transcoded contents/value of that element.  INFO is a communication
channel for the export process."
  ;; Preserve newline characters with the white-space CSS property
  (format "<div style=\"white-space: pre\">\n%s\n</div>" (string-trim contents)))

(defun ox-mdx--headline-text-to-slug (headline)
  "Slugify HEADLINE's text.
Return a slug for the HEADLINE element suitable for use as a URL anchor.
This function converts the text of HEADLINE to lowercase, replaces
spaces with hyphens, and removes any characters that are not
alphanumeric or hyphens.

In the special case where HEADLINE's text is an empty string, return
\"headline\".

HEADLINE is an org headline element.  INFO is the current export state,
as a plist."
  (let* ((title (org-element-property :title headline))
         (raw (org-no-properties (org-element-interpret-data title)))
         (lowercased (downcase raw))
         (trimmed (string-trim lowercased))
         (hyphenated (replace-regexp-in-string "[[:space:]]+" "-" trimmed))
         (cleaned (replace-regexp-in-string "[^a-z0-9-]" "" hyphenated))
         (deduplicated (replace-regexp-in-string "-+" "-" cleaned))
         (result (string-trim deduplicated "-")))
    (if (string-empty-p result) "headline" result)))

(defun org-mdx--export-get-reference-advice (orig datum info)
  "Advice for `org-export-get-reference' to generate stable IDs.
Normally,`org-export-get-reference' generates randomized IDs \(see
`org-export-new-reference') that are used as the values of the id
attributes of elements throughout the document.  Advise the generation
of these IDs specially for the `mdx' backend such that they are
stable (unchanging) across exports: - For headlines, generate a
deterministic slug from the headline text, appending a counter only for
duplicates.  - For other elements, generate a reference of the form
TYPE-N.  When not using the `mdx' backend, call
`org-export-get-reference' normally.

Important note: although the exported content uses these fixed IDs, the
final version presented on the site may use different ones, depending on
how the MDX file is processed.  For instance, by default,Astro will use
the Rehype-slug plugin (see https://github.com/rehypejs/rehype-slug) to
generate id attributes for headings, which will overwrite the ones
generated here.

ORIG is the original function.  See `org-export-get-reference' for a
description of DATUM and INFO."
  (if (not (eq (org-export-backend-name (plist-get info :back-end)) 'mdx))
      (funcall orig datum info)
    ;; Design note: keep a cache in INFO like
    ;; `org-export-get-reference' does
    (let ((cache (plist-get info :internal-references)))
      (or (car (rassq datum cache))
          (let* ((type (org-element-type datum))
                 (reference
                  (if (org-element-type-p datum 'headline)
                      ;; For headlines: SLUG-N counter after the first
                      ;; duplicate headline
                      (let* ((slug-cache
                              ;; Table of DATUM to slug
                              (or (plist-get info :mdx-headline-slug-cache)
                                  (let ((table (make-hash-table :test #'eq)))
                                    (plist-put info :mdx-headline-slug-cache table)
                                    table)))
                             (cached (gethash datum slug-cache)))
                        (or
                         ;; If DATUM has a matching reference already,
                         ;; just return it
                         cached
                         ;; New headline element, so compute new slug
                         ;; then cache the relevant info.  We also
                         ;; have to have another cache for the number
                         ;; of times a given base slug appears, so as
                         ;; to increment appropriately
                         (let* ((base-slug (ox-mdx--headline-text-to-slug datum))
                                (slug-counts
                                 ;; Table of BASE-SLUG to count
                                 (or (plist-get info :mdx-headline-slug-counts)
                                     (let ((table (make-hash-table :test #'equal)))
                                       (plist-put info :mdx-headline-slug-counts table)
                                       table)))
                                (n (gethash base-slug slug-counts 0))
                                (final-slug (if (zerop n)
                                                base-slug
                                              (format "%s-%d" base-slug n))))
                           (puthash base-slug (1+ n) slug-counts)
                           (puthash datum final-slug slug-cache)
                           final-slug)))
                    ;; For non-headlines: simple TYPE-N counter.
                    (let* ((counters
                            (or (plist-get info :mdx-display-type-counters)
                                (let ((table (make-hash-table :test #'eq)))
                                  (plist-put info :mdx-display-type-counters table)
                                  table)))
                           (display-type
                            (cond ((and (eq type 'paragraph)
                                        (org-html-standalone-image-p datum info))
                                   'figure)
                                  (t type)))
                           (n (1+ (gethash display-type counters 0))))
                      (puthash display-type n counters)
                      (format "%s-%d" display-type n))))
                 (cache (cons (cons reference datum) cache)))
            (plist-put info :internal-references cache)
            reference)))))
;; We use advice rather than redefining the functions that
;; `org-export-get-reference' uses because there are many callers of
;; `org-export-get-reference' for various DATUMs, e.g., figures,
;; headlines, src blocks -- it's easier to just advise it
(advice-add 'org-export-get-reference :around #'org-mdx--export-get-reference-advice)

(el-patch-defun (el-patch-swap org-md-link org-mdx-link) (link desc info)
  "Transcode LINK object into Markdown format.
DESC is the description part of the link, or the empty string.
INFO is a plist holding contextual information.  See
`org-export-data'."
  (let* ((link-org-files-as-md-maybe
          (lambda (raw-path)
            ;; Treat links to `file.org' as links to `file.md'.
            (if (and
                 (plist-get info :md-link-org-files-as-md)
                 (string= ".org" (downcase (file-name-extension raw-path "."))))
                (concat (file-name-sans-extension raw-path) ".md")
              raw-path)))
         (type (org-element-property :type link))
         (raw-path (org-element-property :path link))
         (path (cond
                ((string-equal  type "file")
                 (org-export-file-uri (funcall link-org-files-as-md-maybe raw-path)))
                (t (concat type ":" raw-path)))))
    (cond
     ;; Link type is handled by a special function.
     ((org-export-custom-protocol-maybe link desc 'md info))
     ((member type '("custom-id" "id" "fuzzy"))
      (let ((destination (if (string= type "fuzzy")
                             (org-export-resolve-fuzzy-link link info)
                           (org-export-resolve-id-link link info))))
        (pcase (org-element-type destination)
          (`plain-text                  ; External file.
           (let ((path (funcall link-org-files-as-md-maybe destination)))
             (if (not desc) (format "<%s>" path)
               (format "[%s](%s)" desc path))))
          (`headline
           (format
            "[%s](#%s)"
            ;; Description.
            (cond ((org-string-nw-p desc))
                  ((org-export-numbered-headline-p destination info)
                   (mapconcat #'number-to-string
                              (org-export-get-headline-number destination info)
                              "."))
                  (t (org-export-data (org-element-property :title destination)
                                      info)))
            ;; Reference.
            (or (org-element-property :CUSTOM_ID destination)
                (org-export-get-reference destination info))))
          (_
           (let ((description
                  (or (org-string-nw-p desc)
                      (let ((number (org-export-get-ordinal destination info)))
                        (cond
                         ((not number) nil)
                         ((atom number) (number-to-string number))
                         (t (mapconcat #'number-to-string number ".")))))))
             (when description
               (format "[%s](#%s)"
                       description
                       (org-export-get-reference destination info))))))))
     ((org-export-inline-image-p link org-html-inline-image-rules)
      (let ((path (cond ((not (string-equal type "file"))
                         (concat type ":" raw-path))
                        ((not (file-name-absolute-p raw-path)) raw-path)
                        (t (expand-file-name raw-path))))
            (caption (org-export-data
                      (org-export-get-caption
                       (org-element-parent-element link))
                      info))
            (el-patch-add
              ;; When we are exporting to a buffer, we leave the link
              ;; paths as they are.  However, when we are exporting to
              ;; a file, we copy the asset (e.g., image) over to the
              ;; appropriate location and modify the link to point to
              ;; the appropriate path on the website
              (path
               (if (plist-get info :output-file)
                   (org-mdx--copy-attachments raw-path info)
                 path))))
        (format "![img](%s)"
                (if (not (org-string-nw-p caption)) path
                  (format "%s \"%s\"" path caption)))))
     ((string= type "coderef")
      (format (org-export-get-coderef-format path desc)
              (org-export-resolve-coderef path info)))
     ((string= type "radio")
      (let ((destination (org-export-resolve-radio-link link info)))
        (if (not destination) desc
          (format "<a href=\"#%s\">%s</a>"
                  (org-export-get-reference destination info)
                  desc))))
     (t (if (not desc) (format "<%s>" path)
          (format "[%s](%s)" desc path))))))

(defun org-mdx--frontmatter-quote-string (s)
  "Quote string S for YAML double-quoted scalars."
  (concat "\""
          (thread-last s
                       (replace-regexp-in-string "\\\\" "\\\\\\\\") ; \ -> \\
                       (replace-regexp-in-string "\"" "\\\\\"") ; " -> \"
                       (replace-regexp-in-string "\n" "\\\\n") ; newline -> \n
                       (replace-regexp-in-string "\t" "\\\\t")) ; tab -> \t
          "\""))

(defun org-mdx-template (contents info)
  "Return complete document string after Markdown conversion.
CONTENTS is the transcoded contents string (returned by the
inner-template backend transcoder).  INFO is a plist used as a
communication channel for the export process."
  (let* ((raw-title (org-mdx--frontmatter-quote-string
                     (org-mdx-plain-text
                      (org-element-interpret-data (plist-get info :title))
                      info)))
         (title (when raw-title (concat "title: " raw-title)))
         (date-timestamp (car (plist-get info :date)))
         (date
          (when date-timestamp
            (concat "date: " (org-format-timestamp date-timestamp "%FT%T%:z")))) ; YAML 1.1 timestamp spec
         (frontmatter (string-trim (string-join (list title date) "\n"))))
    (concat
     "---\n"
     frontmatter
     "\n---\n"
     contents)))

;;;;; Exporters

;; Export to buffer
(defun org-mdx-export-as-mdx
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to an MDX buffer.
If narrowing is active in the current buffer, only export its narrowed
part.

If a region is active, export that region.

See the docstring of `org-md-export-as-markdown' for a description of
the ASYNC, SUBTREEP, VISIBLE-ONLY, and BODY-ONLY arguments.

EXT-PLIST, when provided, is a property list with external parameters
overriding Org default settings, but still inferior to file-local
settings.

Export result is inserted into a buffer named \"*Org MDX Export*\",
which is displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (org-export-to-buffer 'mdx "*Org MDX Export*"
    async subtreep visible-only body-only ext-plist
    #'markdown-mode))

(defun org-mdx--title-to-ascii (info)
  "Return the document title as an ASCII string.
Convert the document title to a ASCII string via the ASCII exporter.
Returns nil if :with-title is not set in INFO

INFO is a plist holding export information."
  (string-trim
   (org-export-string-as
    (org-element-interpret-data
     (when (plist-get info :with-title)
       (plist-get info :title)))
    'ascii t `(;; Export to ASCII, as opposed to e.g. UTF-8
               :ascii-charset ascii
               ;; Newlines may be inserted to wrap the text according
               ;; to :ascii-text-width or `org-ascii-text-width.'
               ;; Prevent this
               :ascii-text-width ,most-positive-fixnum))))

(defun org-mdx--title-to-slug (title)
  "Transform TITLE into a slug.
This slug is used as the directory name associated with a post."
  (thread-last (downcase title)
               (replace-regexp-in-string "[^a-z0-9]+" "_")
               (replace-regexp-in-string
                "-+" "-")))

(defun org-mdx--output-directory (output-dir &optional subtreep)
  "Return the output directory path of the current post.
Return a directory path relative to OUTPUT-DIR.  If OUTPUT-DIR is nil,
then the output path is relative to `default-directory'.


The returned path takes the form of \"TIMESTAMP--SLUG\", where TIMESTAMP
is based on the date property of the post and SLUG is the title of the
post passed to `org-mdx--title-to-slug'.

This function is called from the point in org buffer to-be exported.

With a non-nil optional argument SUBTREEP, use the \"EXPORT_FILE_NAME\"
property of subtree at point as the SLUG portion of the output
directory."
  (let* ((info (org-export-get-environment 'mdx))
         (title (org-mdx--title-to-ascii info))
         (date-timestamp (car (plist-get info :date)))
         (directory
          (or
           ;; Check EXPORT_FILE_NAME subtree property (when SUBTREEP
           ;; is non-nil)
           (when subtreep (org-entry-get nil "EXPORT_FILE_NAME" 'selective))
           ;; REVIEW 2026-03-27: Should I do this? I'm going to
           ;; standardize the file names anyway...
           ;;
           ;; Check #+EXPORT_FILE_NAME keyword
           (org-with-point-at (point-min)
             (catch :found
               (let ((case-fold-search t))
                 (while (re-search-forward "^[ \t]*#\\+EXPORT_FILE_NAME:[ \t]+\\S-" nil t)
                   (let ((element (org-element-at-point)))
                     (when (org-element-type-p element 'keyword)
                       (throw :found (org-element-property :value element))))))))
           ;; Determine export file path for buffer
           (format "%s--%s"
                   (org-format-timestamp date-timestamp "%Y%m%d%H%M")
                   (org-mdx--title-to-slug title))
           ;; As a fallback, ask user
           (read-file-name "Output directory: " org-mdx-posts-dir))))
    (expand-file-name directory output-dir)))

(defun org-mdx--copy-attachments (path info)
  "Copy asset at PATH to the post subdirectory.
Return the path of the asset relative to the post subdirectory.  Uses
the value of the `:personal-site-output-directory' property in INFO to
do so.

PATH is the absolute path of the local asset.  INFO is a plist used as a
communication channel."
  (let* ((output-file (plist-get info :output-file))
         (output-dir (if output-file
                         (file-name-directory output-file)
                       default-directory))
         (filename (file-name-nondirectory path))
         (asset-subdir (expand-file-name "assets" output-dir))
         (asset-path (expand-file-name filename asset-subdir))
         (link-path filename))
    ;; TODO 2026-04-04: Assumes that attachments are uniquely named.
    ;; Perhaps allow non-unique attachment file names by appending a
    ;; number after each duplicate?
    (if (file-exists-p asset-path)
        (message "[org-mdx] Asset %s already exists, not overwriting" asset-path)
      (unless (file-exists-p asset-subdir)
        (make-directory asset-subdir))
      (copy-file path asset-path nil))
    (file-name-concat "assets" link-path)))

(defun org-mdx--prepare-output-directory (output-directory)
  "Prepare output directory for generation of exported files.
OUTPUT-DIRECTORY is the targeted output directory.  Create
OUTPUT-DIRECTORY if it does not exist.  If it does, delete any existing
files and subdirectories within it.

This function should be used in any export function that outputs to a
file on disk (as opposed to just a buffer).  See `org-mdx-export-to-mdx'
and `org-mdx-publish-to-site'."
  (if (file-exists-p output-directory)
      ;; Clear out DIRECTORY if it already exists
      (mapc (lambda (f)
              (if (file-directory-p f)
                  (delete-directory f)
                (delete-file f)))
            (directory-files-recursively output-directory ".*" t))
    ;; Make DIRECTORY if it doesn't exist yet
    (make-directory output-directory)))

;; Export to file
(defun org-mdx-export-to-mdx
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a post subdirectory.
The post subdirectory is one calculated by `org-mdx--output-directory'.
Several files may be created in this directory:
- An \"index.mdx\", containing the post in MDX form.
- An \"assets/\" subdirectory, containing all attachments (see
  `org-mdx--copy-attachments').
These files constitute all the files needed for the post page.

If narrowing is active in the current buffer, only export its narrowed
part.

If a region is active, export that region.

See the docstring of `org-md-export-to-markdown' for a description of
the ASYNC, SUBTREEP, VISIBLE-ONLY, and BODY-ONLY arguments.

EXT-PLIST, when provided, is a property list with external parameters
overriding Org default settings, but still inferior to file-local
settings.

Return the output directory's name."
  (interactive)
  (let* ((output-dir (or (plist-get ext-plist :mdx-output-dir) ; From `org-mdx-publish-to-site'
                         (org-mdx--output-directory nil subtreep)))
         (outfile (expand-file-name "index.mdx" output-dir)))
    (org-mdx--prepare-output-directory output-dir)
    (org-export-to-file 'mdx outfile async subtreep visible-only)))

;;;;; Define backend

;; For more information about backends and the exporting process, see
;; (org) Advanced Export Configuration.
(org-export-define-derived-backend 'mdx 'md
  ;; Entry for backend in the org export menu
  :menu-entry
  '(?s "Export to site"
       ((?M "To buffer" org-mdx-export-as-mdx)
        (?m "To file" org-mdx-export-to-mdx)
        (?o "To file and open"
            (lambda (async subtreep visible-only body-only)
              (if async
                  (org-mdx-export-to-mdx t subtreep visible-only body-only)
                (pop-to-buffer
                 (find-file-noselect
                  (org-mdx-export-to-mdx nil subtreep visible-only body-only))))))))

  ;; Used to modify or remove org elements on export, overwriting the
  ;; filters of the parent backend.  See (info "(org) Advanced Export
  ;; Configuration") for more information on backend filters
  ;; :filters-alist

  ;; Used to define new options or overwrite those of the parent
  ;; backend
  :options-alist
  '((:html-self-link-headlines nil "html-self-link-headlines" t))
  
  ;; Used to add new transcoders or overwrite those of the parent
  ;; backend.  See `org-export-define-backend' for more information on
  ;; backend transcoders
  :translate-alist
  '((template . org-mdx-template)
    (plain-text . org-mdx-plain-text)
    (example-block . org-mdx-example-block)
    (src-block . org-mdx-src-block)
    (special-block . org-mdx-special-block)
    (link . org-mdx-link)))

;;;; Org-publish
;; I use org-publish to make it easier to export all my blog posts all
;; together.  The export function `org-mdx-export-to-mdx' does all
;; the heavy lifting for export.

(defun org-mdx-publish-to-site (plist filename pub-dir)
  "Publish an org file to a post subdirectory.
PLIST is the property list for the current project.  FILENAME is the
filename of the org file to be published.  PUB-DIR is the publishing
directory.

This function is used as the :publishing-function in
`org-publish-project-alist'."
  ;; We can't use `org-publish-org-to' directly because that would use
  ;; `org-export-output-file-name' instead of our
  ;; `org-mdx--output-directory' to determine the output file.  So we
  ;; define a modified version of `org-publish-org-to' instead
  (let ((org-inhibit-startup t))
    (org-with-file-buffer filename
      (let* ((output-dir (org-mdx--output-directory pub-dir)))
        (org-mdx--prepare-output-directory output-dir)

        (org-mdx-export-to-mdx
         nil nil nil (plist-get plist :body-only)
         (org-combine-plists
          plist
          `( :mdx-output-dir ,output-dir ; Pass to `org-mdx-export-to-mdx'
             :crossrefs ,(org-publish-cache-get-file-property
                          (file-truename filename) :crossrefs nil t)
             :filter-final-output (org-publish--store-crossrefs
                                   org-publish-collect-index
                                   ,@(plist-get plist :filter-final-output)))))))))

;; Make compiler happy
(defvar krisb-manuscript-blog-posts-directory)

(setopt
 ;; NOTE 2026-02-12: This is set to nil as I develop, to force
 ;; publishing every file.  When in use, a value of t is more
 ;; appropriate.
 org-publish-use-timestamps-flag nil
 org-publish-project-alist
 `(("posts"
    :base-directory ,krisb-manuscript-blog-posts-directory
    :publishing-directory ,org-mdx-posts-dir
    :base-extension "org"
    :recursive t
    :publishing-function org-mdx-publish-to-site
    :html-head-include-default-style nil
    :html-prefer-user-labels nil
    :with-toc nil
    :with-tags nil
    :with-todo-keywords nil
    :time-stamp-file nil)))

;;; Provide
(provide 'ox-mdx)
;;; ox-mdx.el ends here
