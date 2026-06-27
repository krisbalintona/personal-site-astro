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

(defconst org-mdx-root-dir
  (expand-file-name
   (project-root
    (project-current nil (file-name-directory (or load-file-name (buffer-file-name))))))
  "Root directory of project.
This option is used to define the value of other relevant paths.")

(defconst org-mdx-content-dir (expand-file-name "src/content/" org-mdx-root-dir)
  "Directory where all MDX content resides.")

(defvar org-mdx-default-alt-text "img"
  "Default alt text used for `img' and `svg' HTML tags.
This variable can be `let'-bound to change the default string.")

(defvar org-mdx-import-statement-alist
  '(("Alert" . "import Alert from \"@components/markup/Alert.astro\";")
    ("Image" . "import { Image } from \"astro:assets\";")
    ("Details" . "import Details from \"@components/markup/Details.astro\";")
    ("Timestamp" . "import Timestamp from \"@components/markup/Timestamp.astro\";")
    ("ContentLink" . "import ContentLink from \"@components/markup/ContentLink.astro\";")
    ("FootnoteSection" . "import FootnoteSection from \"@components/markup/FootnoteSection.astro\";")
    ("Footnote" . "import Footnote from \"@components/markup/Footnote.astro\";")
    ("FootnoteRef" . "import FootnoteRef from \"@components/markup/FootnoteRef.astro\";")
    ("Heading" . "import Heading from \"@components/markup/Heading.astro\";")
    ("Center" . "import Center from \"@components/markup/Center.astro\";"))
  "Alist from component name to import statement.
There are several components specific to this project.  This is an alist
from component name to the import statement corresponding to that
component.

The import statements are like the following

  \"import Alert from \"components/Alert.astro\"\"")

;;;; Backend

;;;;; Functions

(defun org-mdx--register-import (info component-name)
  "Register a component import into INFO.
If COMPONENT-NAME is already registered, don't duplicate the import
statement."
  (let* ((existing-imports (plist-get info :mdx-imports))
         (import-statement (assoc component-name org-mdx-import-statement-alist)))
    (unless import-statement
      (error "Component \"%s\" has no associated import statement" component-name))
    (unless (assoc component-name existing-imports)
      (plist-put info :mdx-imports
                 (cons import-statement existing-imports)))))

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

(defun org-mdx-example-block (example-block _contents info)
  "Transcode EXAMPLE-BLOCK element into MDX format.
Wrap in a fenced code block.

EXAMPLE-BLOCK is org element example block.  _CONTENTS is always nil for
example blocks.  INFO is a plist holding information for the export
process."
  (let ((block-text (string-trim-right
                     (org-remove-indentation
                      (org-export-format-code-default example-block info)))))
    (format "```\n%s\n```" block-text)))

(defun org-mdx--create-figure (fig caption &optional class)
  "Return an HTML figure if necessary.
FIG, CAPTION, and CLASS are strings.  CAPTION is a figure caption and
FIG is the figure itself (e.g., image).

When CAPTION is a non-empty string, return a string of this form:

  <figure>
    FIG
    <figcaption>CAPTION</figcaption>
  </figure>

when CAPTION is nil or an empty sting, then return FIG.

When CLASS is non-nil, it is the string passed to the figure tag's
\"class\" attribute."
  (format "<figure%s>\n%s\n</figure>"
          (if class (format " class=\"%s\"" class) "")
          (if (org-string-nw-p caption)
              (format "%s\n<figcaption>%s</figcaption>"
                      (string-trim fig) caption)
            fig)))

(defun org-mdx-src-block (src-block _contents info)
  "Transcode a SRC-BLOCK element from Org to a markdown fenced code block.
SRC-BLOCK is org element src block.  CONTENTS is always nil for src
blocks.  INFO is a plist holding information for the export process.

Return the src block as CommonMark fenced code block, with special
tweaks for some languages.  For example, the following Org source block:

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
  (let* ((lang (org-element-property :language src-block))
         (inner (org-remove-indentation
                 (org-export-format-code-default src-block info))))
    (pcase lang
      ("d2"
       (let* ((caption
               (let* ((raw-caption
                       (car (org-element-property :caption src-block)))) ; First #+CAPTION value
                 (when raw-caption
                   (substring-no-properties
                    (org-element-interpret-data raw-caption)))))
              (info-string
               (let* ((org-mdx-default-alt-text "diagram")
                      (raw-alt (org-export-read-attribute :attr_mdx src-block :alt))
                      (alt-text
                       ;; The title attribute becomes the alt-text.
                       ;; See
                       ;; https://astro-d2.vercel.app/examples/attributes/title/
                       (format "title=\"%s\""
                               (if raw-alt
                                   ;; Quotation marks are the only
                                   ;; characters that need escaping
                                   (replace-regexp-in-string "\"" "\\\\\"" raw-alt)
                                 org-mdx-default-alt-text))))
                 (org-string-nw-p (string-join (delq nil (list alt-text)) " "))))
              (code-fence
               (format "```%s%s\n%s\n```"
                       lang
                       (if info-string
                           (concat " " (string-trim info-string))
                         "")
                       (string-trim inner))))
         (org-mdx--create-figure code-fence caption)))
      (_
       (format "```%s\n%s\n```" lang (string-trim inner))))))

(defun org-mdx-special-block (special-block contents info)
  "Transcode SPECIAL-BLOCK element into MDX format.
SPECIAL-BLOCK is a special block org element.  CONTENTS is the
transcoded contents/value of that element.  INFO is a communication
channel for the export process."
  (pcase (org-element-property :type special-block)
    ("alert"
     (org-mdx--register-import info "Alert")
     (format "<Alert>\n%s\n</Alert>" (string-trim contents)))
    ;; Handle both the summary and details blocks here.  A neat side
    ;; effect is that a summary block without a details block falls to
    ;; the fallback case (which is what we want)
    ("details"
     (org-mdx--register-import info "Details")
     (let* ((children (org-element-contents special-block))
            (summary-block
             (car (member-if (lambda (c) (string= (org-element-property :type c) "summary"))
                             children)))
            (body-children (if summary-block
                               (remove summary-block children)
                             children))
            (summary
             (when summary-block
               ;; Interpret (into a string) the contents of
               ;; SUMMARY-BLOCK's children, not the entire block
               (org-export-data (org-element-contents summary-block) info)))
            (body (mapconcat (lambda (c) (org-export-data c info)) body-children)))
       (format "<Details>\n<Fragment slot=\"summary\">\n%s\n</Fragment>\n%s\n</Details>"
               summary body)))
    ;; Fallback case: wrap in div and preserve newline characters with
    ;; the white-space CSS property
    (_
     (format "<div style=\"white-space: pre\">\n%s\n</div>" (string-trim contents)))))

(defun org-mdx--headline-text-to-slug (headline)
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

(defun org-mdx-headline (headline contents info)
  "Transcode a HEADLINE element from Org to MDX.
CONTENTS holds the contents of the headline.  INFO is a plist holding
contextual information."
  (unless (org-element-property :footnote-section-p headline)
    (let* ((numberedp (org-export-numbered-headline-p headline info))
           (numbers (org-export-get-headline-number headline info))
           (level (+ (org-export-get-relative-level headline info)
                     (1- (plist-get info :md-toplevel-hlevel))))
           (todo (and (plist-get info :with-todo-keywords)
                      (let ((todo (org-element-property :todo-keyword headline)))
                        (and todo (org-export-data todo info)))))
           (todo-type (and todo (org-element-property :todo-type headline)))
           (priority (and (plist-get info :with-priority)
                          (org-element-property :priority headline)))
           (text (org-export-data (org-element-property :title headline) info))
           (tags (and (plist-get info :with-tags)
                      (org-export-get-tags headline info)))
           (full-text (funcall (plist-get info :html-format-headline-function)
                               todo todo-type priority text tags info))
           (contents (or contents ""))
           (id (org-html--reference headline info))
           (self-link-p (plist-get info :html-self-link-headlines)))
      (if (org-export-low-level-p headline info)
          ;; This is a deep subtree: export it as a list item.  (See
          ;; the :headline-levels export option and
          ;; `org-export-headline-levels'.)
          ;;
          ;; TODO 2026-05-02: This function is based on
          ;; `org-html-headline'.  But I found that the if branch that
          ;; handles deep headlines is broken.  Below is my fix.  I
          ;; should prepare an upstream fix for this at some point.
          ;; Or at least create a bug report with a working prototype
          ;; shown, and let someone else (e.g., Ihor) implement an
          ;; upstream-ready version.
          (let* ((formatted-text
                  (if self-link-p
                      (format "<a class=\"heading-self-link\" href=\"#%s\">%s</a>" id full-text)
                    full-text))
                 (html-type (if numberedp "ol" "ul"))
                 (parent (org-export-get-parent headline))
                 (parent-low-level-p (and parent
                                          (org-export-low-level-p parent info)))
                 (children (org-element-contents headline))
                 (section-contents
                  (mapconcat (lambda (child)
                               (if (org-element-type-p child 'section)
                                   (org-export-data child info)
                                 ""))
                             children ""))
                 (child-headlines
                  (mapconcat (lambda (child)
                               (if (org-element-type-p child 'headline)
                                   (org-export-data child info)
                                 ""))
                             children "")))
            (concat
             ;; Opening `ol' or `ul' tag
             (and (not parent-low-level-p)
                  (format "<%s class=\"org-%s\">\n" html-type html-type))
             ;; Other headlines and their content as list items
             (org-html-format-list-item
              section-contents
              (if numberedp 'ordered 'unordered)
              nil info nil
              ;; 2026-05-02: Prepend with newline since without it
              ;; MDX's parser complains
              (concat "\n" (org-html--anchor id nil nil info) formatted-text))
             child-headlines
             ;; Closing `ol' or `ul' tag
             (and (not parent-low-level-p)
                  (format "</%s>\n" html-type))))
        ;; Standard headline
        (let ((headline-class
               (org-element-property :HTML_HEADLINE_CLASS headline))
              (first-content (car (org-element-contents headline))))
          (org-mdx--register-import info "Heading")
          (format "%s\n%s\n"
                  (format "<Heading level=\"%d\" id=\"%s\"%s%s>%s</Heading>\n"
                          level
                          id
                          (if headline-class
                              (format " class=\"%s\"" headline-class)
                            "")
                          (if self-link-p
                              "selfLink={true}"
                            "")
                          (concat (when numberedp
                                    (format "<span class=\"heading-number-%d\">%s</span> "
                                            level
                                            (concat (mapconcat #'number-to-string numbers ".") ".")))
                                  full-text))
                  ;; When there is no section, pretend there is an
                  ;; empty one to get the correct <div
                  ;; class="outline-...> which is needed by
                  ;; `org-info.js'.
                  (if (org-element-type-p first-content 'section)
                      contents
                    (concat (org-html-section first-content "" info) contents))))))))

(defun org-mdx-timestamp (timestamp _contents info)
  "Transcode a TIMESTAMP object from Org to MDX.
Passes to a Timestamp JSX component.

CONTENTS is nil.  INFO is a plist holding contextual information."
  (let* ((ts (org-element-put-property (org-element-copy timestamp t) :post-blank 0))
         (date (org-timestamp-format ts "%Y-%m-%d"))
         (time (when (org-element-property :hour-start ts)
                 (org-timestamp-format ts "%H:%M"))))
    (org-mdx--register-import info "Timestamp")
    (if time
        (format "<Timestamp date=\"%s\" time=\"%s\" />" date time)
      (format "<Timestamp date=\"%s\" />" date))))

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
                         (let* ((base-slug (org-mdx--headline-text-to-slug datum))
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
                (t (concat type ":" raw-path))))
         ;; TODO 2026-04-28: Only work with ID links.  Should we
         ;; expand more than that type of link?  If so, which ones,
         ;; and can we support them more generically
         ;;
         ;; Bespoke support for portion of link after "::", which is
         ;; used e.g. when linking to a CUSTOM_ID in an ID link.  See
         ;; below
         (el-patch-add
           (compound-p
            (and (string= type "id")
                 (string-match "\\(.*?\\)::\\(.*\\)" raw-path)))
           (file-id
            (when compound-p (match-string 1 raw-path)))
           (search-term
            (when compound-p
              (let ((s (match-string 2 raw-path)))
                (if (string-prefix-p "#" s)
                    (substring s 1)
                  s))))))
    (cond
     ;; Link type is handled by a special function.
     ((org-export-custom-protocol-maybe link desc 'md info))
     ((member type '("custom-id" "id" "fuzzy"))
      (let ((destination
             (if (string= type "fuzzy")
                 (org-export-resolve-fuzzy-link link info)
               (el-patch-swap
                 (org-export-resolve-id-link link info)
                 (if compound-p
                     (or (cdr (assoc file-id (plist-get info :id-alist)))
                         (car (org-id-find file-id)))
                   (org-export-resolve-id-link link info))))))
        (pcase (org-element-type destination)
          ;; (External) file destination (even if headline or other
          ;; element)
          (`plain-text
           (el-patch-swap
             (let ((path (funcall link-org-files-as-md-maybe destination)))
               (if (not desc)
                   (format "<%s>" path)
                 (format "[%s](%s)" desc path)))
             (let* ((destination-project
                     (org-publish-get-project-from-filename destination))
                    (destination-full-path
                     (expand-file-name destination
                                       (plist-get destination-project :base-directory)))
                    (collection-name
                     (format "collectionName=\"%s\"" (car destination-project)))
                    (id
                     ;; Since our content collection uses the
                     ;; directory name generated by
                     ;; `org-mdx--output-directory' for entry IDs, we
                     ;; use that here
                     (format "id=\"%s\""
                             (let* ((cache (or (plist-get info :mdx-destination-id-cache)
                                               (let ((table (make-hash-table :test #'equal)))
                                                 (plist-put info :mdx-destination-id-cache table)
                                                 table)))
                                    (cached (gethash destination-full-path cache))
                                    (existing-buf (find-buffer-visiting destination-full-path))
                                    buf)
                               (or cached
                                   (unwind-protect
                                       (let* (result)
                                         (setq buf (find-file-noselect destination-full-path)
                                               result (with-current-buffer buf
                                                        ;; We just need the subdir name
                                                        (file-name-base (org-mdx--output-directory nil))))
                                         (puthash destination-full-path result cache)
                                         result))
                                   (when (and buf (not existing-buf))
                                     (kill-buffer buf))))))
                    (anchor (when (org-string-nw-p search-term) (format "anchor=\"%s\"" search-term)))
                    (description (org-string-nw-p desc)))
               (if (not destination-project)
                   ;; TODO 2026-04-28: Consider allowing such links to
                   ;; be exported but ensure there is an appropriately
                   ;; descriptive 404 page?
                   ;;
                   ;; ID links to entries without a project are
                   ;; considered "broken" (adhering to the value of
                   ;; `org-export-with-broken-links')
                   (signal 'org-link-broken (list file-id))
                 (unless collection-name
                   (error "Entry with ID %s has no collection name" id))
                 (unless id
                   (error "Entry with ID %s does not exist" id))
                 (org-mdx--register-import info "ContentLink")
                 (format "<ContentLink %s %s%s>%s</ContentLink>"
                         collection-name id
                         (if (org-string-nw-p anchor) (concat " " anchor) "")
                         description)))))
          ;; Same-file headline destination
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
            ;; Reference
            (or (org-element-property :CUSTOM_ID destination)
                (org-export-get-reference destination info))))
          ;; Non-headline destination, e.g.,source blocks, tables,
          ;; paragraphs, standalone figures
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
     ;; Images
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
              (alt-text
               (or (org-export-read-attribute :attr_mdx (org-element-parent-element link) :alt)
                   org-mdx-default-alt-text)))
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
        (el-patch-remove
          (format "![img](%s)"
                  (if (not (org-string-nw-p caption)) path
                    (format "%s \"%s\"" path caption))))
        (el-patch-add
          (org-mdx--register-import info "Image")
          (org-mdx--create-figure
           (format "<Image src={import(\"%s\")} alt=\"%s\" />" path alt-text)
           caption
           (org-export-read-attribute :attr_mdx (org-element-parent-element link) :class)))))
     ((string= type "coderef")
      (format (org-export-get-coderef-format path desc)
              (org-export-resolve-coderef path info)))
     ((string= type "radio")
      (let ((destination (org-export-resolve-radio-link link info)))
        (if (not destination) desc
          (format "<a href=\"#%s\">%s</a>"
                  (org-export-get-reference destination info)
                  desc))))
     (t (if (not desc)
            ;; Angle brackets are JSX syntax, meaning they cannot be
            ;; inserted to denote bare links.  Instead, for bare
            ;; links, we simply set the description to the path.  This
            ;; way, bare links are proper links (as intended).
            (el-patch-swap
              (format "<%s>" path)
              (format "[%s](%s)" path path))
          (format "[%s](%s)" desc path))))))

(defun org-mdx-item (item contents info)
  "Transcode an ITEM element for MDX export.
Ordered and unordered list items are handled by `org-md-item'.
Descriptive list items are emitted as HTML `dt'/`dd' pairs, since
Markdown has no equivalent construct.  In both cases CONTENTS has
already been transcoded to MDX, so footnote references, emphasis, etc.
are preserved correctly.

ITEM is the org element.  CONTENTS holds the transcoded item body.  INFO
is a plist used as a communication channel."
  (let* ((plain-list (org-element-parent item))
         (type (org-element-property :type plain-list)))
    (if (eq type 'descriptive)
        ;; Markdown has no definition list syntax, so in such cases we
        ;; emit HTML
        (let* ((tag (org-element-property :tag item))
               (tag-str (if tag (org-export-data tag info) ""))
               (checkbox (org-element-property :checkbox item))
               (checkbox-str
                (concat (pcase checkbox
                          (`on  "[X] ")
                          (`trans "[-] ")
                          (`off "[ ] ")
                          (_ ""))
                        tag-str))
               (body (if (org-string-nw-p contents)
                         (org-trim contents)
                       "")))
          (concat (format "<dt>%s</dt>\n" checkbox-str)
                  ;; Render as new paragraph to handle the case
                  ;; wherein description list items aren't inline HTML
                  ;; elements (e.g., an item that is another list).
                  ;; Otherwise, invalid MDX is exported (closing tag
                  ;; would not appear on the same line as opening
                  ;; tag).  Use CSS to tweak the spacing if needed
                  (format "<dd>\n%s\n</dd>" body)))
      ;; Ordered and unordered lists: delegate to the MD transcoder
      (org-md-item item contents info))))

(defun org-mdx-center-block (_center-block contents info)
  "Transcode a CENTER-BLOCK element from Org to HTML.
CONTENTS holds the contents of the block.  INFO is a plist holding
contextual information."
  (org-mdx--register-import info "Center")
  (format "<Center>\n%s</Center>" contents))

(defun org-mdx-plain-list (plain-list contents _info)
  "Transcode PLAIN-LIST for MDX export.
Descriptive lists are wrapped in `<dl>'; ordered and unordered lists
fall through to the Markdown plain-list transcoder.

CONTENTS is the plain-list contents.  INFO is a plist used as a
communication channel."
  (if (eq (org-element-property :type plain-list) 'descriptive)
      ;; Markdown has no definition list syntax, so in such cases we
      ;; emit HTML
      (format "<dl>\n%s\n</dl>" (org-trim contents))
    ;; Ordered and unordered lists: delegate to the MD transcoder
    (org-md-plain-list plain-list contents _info)))

(defun org-mdx-footnote-reference (footnote-reference _contents info)
  "Transcode a FOOTNOTE-REFERENCE element from Org to MDX.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let* ((next-element (org-export-get-next-element footnote-reference info))
         (separatorp (org-element-type-p next-element 'footnote-reference))
         (num (org-export-get-footnote-number footnote-reference info))
         (id
          ;; The ID for footnote references is normally based on just
          ;; the name of the footnote linked to.  However, multiple
          ;; references may point to the same footnote.  So to avoid
          ;; HTML element ID conflicts, a number suffix is appended if
          ;; necessary.  (There cannot be multiple footnotes of the
          ;; same name, though.)
          (unless (org-export-footnote-first-reference-p footnote-reference info)
            (format "%s-%d"
                    num
                    (org-export-get-ordinal
                     footnote-reference info '(footnote-reference)
                     `(lambda (ref _plist)
                        (if ,num
                            (equal (org-element-property :label ref) ,num)
                          (not (org-element-property :label ref)))))))))
    (org-mdx--register-import info "FootnoteRef")
    (format "<FootnoteRef num=\"%s\"%s%s />"
            num
            (if id (format " id=\"%s\"" id) "")
            (if separatorp " hasSeparator={true}" ""))))

(defun org-mdx--footnote-formatted (footnote info)
  "Formats a single footnote entry FOOTNOTE.
FOOTNOTE is a list of the form (NUMBER DEFINITION).  INFO is a plist
with contextual information."
  (let* ((n (nth 0 footnote))
         (text (nth 1 footnote)))
    (org-mdx--register-import info "Footnote")
    (format "<Footnote num=\"%s\" slot=\"footnotes\">\n%s\n</Footnote>"
            n text)))

(defun org-mdx--footnote-section (info)
  "Format the footnote section.
INFO is a plist used as a communication channel."
  (let* ((footnote-alist (org-export-collect-footnote-definitions info))
         (footnote-alist
          (cl-loop for (n _label raw) in footnote-alist collect
                   (list n (org-trim (org-export-data raw info))))))
    (when footnote-alist
      (org-mdx--register-import info "FootnoteSection")
      (format "<FootnoteSection>\n%s\n%s\n</FootnoteSection>"
              (org-html--translate "Footnotes" info)
              (mapconcat (lambda (fn) (org-mdx--footnote-formatted fn info))
                         footnote-alist "\n")))))

(defun org-mdx-inner-template (contents info)
  "Return body of document after converting it to MDX syntax.
CONTENTS is the transcoded contents string.  INFO is a plist holding
export options."
  (let ((toc
         (let ((depth (plist-get info :with-toc)))
           (when depth
             (org-md--build-toc info (and (wholenump depth) depth)))))
        (footnotes (org-mdx--footnote-section info)))
    ;; Make sure CONTENTS is separated from table of contents and
    ;; footnotes with at least a blank line.
    (concat
     (when toc (concat toc "\n"))
     contents
     (when footnotes (concat "\n" footnotes)))))

(defun org-mdx--frontmatter-quote-string (s)
  "Quote string S for YAML double-quoted scalars.
This function should be used for any object in the YAML frontmatter of
an MDX file whose type is a string."
  (concat "\""
          (thread-last s
                       (replace-regexp-in-string "\\\\" "\\\\\\\\") ; \ -> \\
                       (replace-regexp-in-string "\"" "\\\\\"") ; " -> \"
                       (replace-regexp-in-string "\n" "\\\\n") ; newline -> \n
                       (replace-regexp-in-string "\t" "\\\\t")) ; tab -> \t
          "\""))

(defun org-mdx--frontmatter-field (key raw-value &optional unquotedp)
  "Return a YAML scalar field \"KEY: VALUE\" for use in MDX frontmatter.
Returns nil if RAW-VALUE is nil or whitespace-only.  When UNQUOTEDP is
non-nil, VALUE is emitted as-is (use for YAML e.g. booleans and
timestamps); otherwise it is double-quoted.

Use this function for single-value org keywords (e.g. #+title, #+date).
For multi-value keywords, use `org-mdx--frontmatter-build-list' instead."
  (when (org-string-nw-p raw-value)
    (concat key ": " (if unquotedp
                         raw-value
                       (org-mdx--frontmatter-quote-string raw-value)))))

(defun org-mdx--frontmatter-build-list (name items)
  "Return a YAML sequence field NAME for use in MDX frontmatter.
ITEMS is a list of already-quoted strings, as returned by e.g.
`org-mdx--frontmatter-parse-keyword-list'.  Returns nil if ITEMS is nil."
  (when items
    (concat name ":\n"
            (mapconcat (lambda (item) (format "  - %s" item)) items "\n"))))

(defun org-mdx--frontmatter-parse-keyword-list (raw-string &optional post-process)
  "Parse a multi-value org keyword value RAW-STRING for use in MDX frontmatter.
Splits RAW-STRING with `split-string-and-unquote' and quotes each
element for YAML.  When POST-PROCESS is a function, it is applied to
each element before quoting (use this to transform values,
e.g. resolving org IDs to titles).  Returns nil if RAW-STRING is nil or
whitespace-only.

Use this function for org keywords that accept a space-separated list of
values (e.g. #+filetags, #+mdx_tags)."
  (when (org-string-nw-p raw-string)
    (mapcar (lambda (s)
              (org-mdx--frontmatter-quote-string
               (funcall (or (and (functionp post-process) post-process) #'identity) s)))
            (split-string-and-unquote (string-trim raw-string)))))

(defun org-mdx--frontmatter (contents info)
  "Return document's formatted YAML frontmatter.
CONTENTS is the transcoded contents string.  INFO is a plist used as a
communication channel for the export process."
  (let* ((entry-type
          (or (plist-get info :mdx-entry-type)
              ;; Infer project when not using org-publish.  Otherwise
              ;; there will be no frontmatter
              (and (buffer-file-name)
                   (car (org-publish-get-project-from-filename (buffer-file-name))))))
         ;; YAML 1.1 timestamp spec
         (timestamp-format "%FT%T%:z")

         ;; Title
         (title (org-mdx--frontmatter-field
                 "title"
                 ;; Export title as HTML to support inline markup
                 ;; (e.g., italics).  The plain text version can be
                 ;; derived by using packages like sanitize-html,
                 ;; stripping tags and replacing entities with their
                 ;; UTF-8 versions.
                 (org-mdx--title-to-html info)))

         ;; Slug
         (slug (org-mdx--frontmatter-field "slug" (plist-get info :mdx-slug)))

         ;; Date
         (pub-date (org-mdx--frontmatter-field
                    "pubDate"
                    (car (ensure-list (org-export-get-date info timestamp-format)))
                    'timestamp))

         ;; Last modification
         (raw-last-mod (plist-get info :mdx-last-mod))
         (last-mod
          (org-mdx--frontmatter-field
           "lastMod"
           (when (org-string-nw-p raw-last-mod)
             (format-time-string timestamp-format (encode-time (org-parse-time-string raw-last-mod))))
           'timestamp))

         ;; Draft
         (draft
          (org-mdx--frontmatter-field "draft" (plist-get info :mdx-draft-p) 'boolean))

         ;; Tags
         (tags
          (org-mdx--frontmatter-build-list
           "tags"
           (org-mdx--frontmatter-parse-keyword-list (plist-get info :mdx-tags))))

         ;; Description
         (description
          (org-mdx--frontmatter-field "description" (plist-get info :description)))

         ;; Threads
         (transform-threads-func ; Convert entry IDs to their corresponding title
          (lambda (s)
            ;; FIXME 2026-05-17: Should we call something like
            ;; (org-id-update-id-locations nil t) before publishing to
            ;; ensure the cache is up to date before export?  Or are
            ;; we okay settling with a potentially stale cache
            ;;
            ;; When S is an (unquoted) ID, then return the title of
            ;; the entry corresponding to that ID.  Otherwise return
            ;; S.
            (if (not (and org-id-locations (gethash s org-id-locations)))
                s
              (org-with-point-at (org-id-find s 'marker)
                (or (org-element-property :title (org-element-at-point))
                    (org-get-title))))))
         (threads
          (org-mdx--frontmatter-build-list
           "threads" (org-mdx--frontmatter-parse-keyword-list
                      (plist-get info :mdx-threads) transform-threads-func)))

         ;; Redirects
         (redirects
          (org-mdx--frontmatter-build-list
           "redirects"
           (org-mdx--frontmatter-parse-keyword-list (plist-get info :mdx-redirects))))

         (frontmatter-base (list title slug draft description)))

    (string-join
     (delq nil
           ;; Emit different frontmatter depending on :mdx-entry-type.
           ;; This should match the schema of collections in my
           ;; project content.config.ts
           (pcase entry-type
             ((or "articles" "notes")
              (append frontmatter-base (list pub-date last-mod tags threads redirects)))
             ("standalone"
              (append frontmatter-base (list pub-date last-mod)))
             (_ frontmatter-base)))
     "\n")))

(defun org-mdx-template (contents info)
  "Return complete document string after Markdown conversion.
CONTENTS is the transcoded contents string (returned by the
inner-template backend transcoder).  INFO is a plist used as a
communication channel for the export process."
  (let ((frontmatter (org-mdx--frontmatter contents info))
        (imports (org-string-nw-p
                  (mapconcat #'cdr (plist-get info :mdx-imports) "\n"))))
    (concat
     (when frontmatter (concat "---\n" frontmatter "\n---\n"))
     (when imports (concat imports "\n\n"))
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

(defun org-mdx--interpret-as-ascii (data charset)
  "Return DATA as an ASCII string.
DATA is a parse tree, an element, an object or a secondary string to
interpret.  CHARSET is the ASCII charset to export to.  For possible
values, see `org-ascii-charset'."
  (string-trim
   (org-export-string-as
    data
    'ascii t `( :ascii-charset ,charset
                ;; Newlines may be inserted to wrap the text according
                ;; to :ascii-text-width or `org-ascii-text-width.'
                ;; Prevent this
                :ascii-text-width ,most-positive-fixnum))))

(defun org-mdx--title-to-ascii (info)
  "Return the document title as an ASCII string.
Convert the document title to a ASCII string via the ASCII exporter.
Returns nil if :with-title is not set in INFO

INFO is a plist holding export information."
  (org-mdx--interpret-as-ascii
   (org-element-interpret-data
    (when (plist-get info :with-title) (plist-get info :title)))
   'ascii))

(defun org-mdx--title-to-html (info)
  "Return the document title as an HTML string.
Convert the document title to an HTML string via the HTML exporter.
Returns nil if :with-title is not set in INFO

INFO is a plist holding export information."
  (org-export-data-with-backend
   (when (plist-get info :with-title) (plist-get info :title))
   'html info))

(defun org-mdx--title-to-subdirectory-name (title)
  "Transform TITLE into a slug.
This slug is used as the directory name associated with an entry."
  (thread-last (downcase title)
               (replace-regexp-in-string "[^a-z0-9]+" "_")
               (replace-regexp-in-string
                "-+" "-")))

(defun org-mdx--output-directory (output-dir &optional subtreep)
  "Return the output directory path of the current entry.
Return a directory path relative to OUTPUT-DIR.  If OUTPUT-DIR is nil,
then the output path is relative to `default-directory'.


The returned path takes the form of \"TIMESTAMP--SLUG\", where TIMESTAMP
is based on the date property of the entry and SLUG is the return value
of the entry title passed to `org-mdx--title-to-subdirectory-name'.

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
                   (org-mdx--title-to-subdirectory-name title))
           ;; As a fallback, ask user
           (read-file-name "Output directory: " org-mdx-content-dir))))
    (expand-file-name directory output-dir)))

(defun org-mdx--copy-attachments (path info)
  "Copy asset at PATH to the entry subdirectory.
Return the path of the asset relative to the entry subdirectory.  Uses
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
  "Export current buffer to a entry subdirectory.
The entry subdirectory is one calculated by `org-mdx--output-directory'.
Several files may be created in this directory:
- An \"index.mdx\", containing the entry in MDX form.
- An \"assets/\" subdirectory, containing all attachments (see
  `org-mdx--copy-attachments').
These files constitute all the files needed for the entry page.

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
    (org-export-to-file 'mdx outfile async subtreep visible-only body-only ext-plist)))

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
  '((:mdx-slug "MDX_SLUG" nil nil)
    (:mdx-draft-p "MDX_DRAFT" "mdx-draft" "true")
    (:mdx-last-mod "MDX_LAST_MOD" nil nil nil)
    (:mdx-tags "MDX_TAGS" nil nil space)
    (:mdx-threads "MDX_THREADS" nil nil space)
    (:mdx-redirects "MDX_REDIRECTS" nil nil space)
    (:md-toplevel-hlevel nil nil 2) ; The title is h1; headings must be lower
    ;; See `org-export-headline-levels' and
    ;; `org-export-options-alist'.  Set :headline-levels to 5 since
    ;; HTML has heading levels up to and including 6 ("h1" is the
    ;; title, heading level one is "h2")
    (:headline-levels nil "H" 5)
    ;; Headlines link to themselves, so users can click on them to
    ;; have an anchor to the headline
    (:html-self-link-headlines nil "html-self-link-headlines" t))

  ;; Used to add new transcoders or overwrite those of the parent
  ;; backend.  See `org-export-define-backend' for more information on
  ;; backend transcoders
  :translate-alist
  '((template . org-mdx-template)
    (inner-template . org-mdx-inner-template)
    (plain-text . org-mdx-plain-text)
    (example-block . org-mdx-example-block)
    (center-block . org-mdx-center-block)
    (src-block . org-mdx-src-block)
    (special-block . org-mdx-special-block)
    (link . org-mdx-link)
    (timestamp . org-mdx-timestamp)
    (footnote-reference . org-mdx-footnote-reference)
    (headline . org-mdx-headline)
    (item . org-mdx-item)
    (plain-list . org-mdx-plain-list)))

;;;; Org-publish
;; I use org-publish to make it easier to export all my blog entries
;; all together.  The export function `org-mdx-export-to-mdx' does all
;; the heavy lifting for export.

(defun org-mdx-publish-to-site (plist filename pub-dir)
  "Publish an org file to an entry subdirectory.
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
(defvar krisb-manuscript-blog-directory)

(let ((base-options '( :with-toc nil
                       :with-tags nil
                       :with-todo-keywords nil
                       :with-broken-links mark
                       :time-stamp-file nil
                       :base-extension "org"
                       :publishing-function org-mdx-publish-to-site)))
  (setopt org-publish-project-alist
          `(;; Posts
            ("articles"
             :base-directory ,(expand-file-name "articles" krisb-manuscript-blog-directory)
             :publishing-directory ,(expand-file-name "articles/" org-mdx-content-dir)
             :recursive t
             :mdx-entry-type "articles"
             ,@base-options)
            ("notes"
             :base-directory ,(expand-file-name "notes" krisb-manuscript-blog-directory)
             :publishing-directory ,(expand-file-name "notes/" org-mdx-content-dir)
             :recursive t
             :mdx-entry-type "notes"
             ,@base-options)
            ("standalone"
             :base-directory ,(expand-file-name "standalone" krisb-manuscript-blog-directory)
             :publishing-directory ,(expand-file-name "standalone/" org-mdx-content-dir)
             :recursive t
             :mdx-entry-type "standalone"
             ,@base-options)
            ;; Taxonomy
            ("tags"
             :base-directory ,(expand-file-name "tags" krisb-manuscript-blog-directory)
             :publishing-directory ,(expand-file-name "tags/" org-mdx-content-dir)
             :recursive t
             :mdx-entry-type "tags"
             ,@base-options)
            ("threads"
             :base-directory ,(expand-file-name "threads" krisb-manuscript-blog-directory)
             :publishing-directory ,(expand-file-name "threads/" org-mdx-content-dir)
             :recursive t
             :mdx-entry-type "threads"
             ,@base-options)
            ;; Remaining
            ("other"
             :base-directory ,(expand-file-name "other" krisb-manuscript-blog-directory)
             :publishing-directory ,(expand-file-name "other/" org-mdx-content-dir)
             :recursive t
             :mdx-entry-type "other"
             ,@base-options))))

;;; Provide
(provide 'ox-mdx)
;;; ox-mdx.el ends here
