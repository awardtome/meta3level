args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) {
  stop("Usage: Rscript build-user-manual-html.R input.md output.html", call. = FALSE)
}

input <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
output <- args[[2]]

if (!requireNamespace("commonmark", quietly = TRUE)) {
  stop("Package 'commonmark' is required to build the manual HTML.", call. = FALSE)
}

lines <- readLines(input, warn = FALSE, encoding = "UTF-8")
if (!length(lines)) stop("The manual source is empty.", call. = FALSE)

# The title is created separately on the Word cover page.
if (grepl("^#[[:space:]]+", lines[[1]])) lines <- lines[-1]

body <- commonmark::markdown_html(
  paste(lines, collapse = "\n"),
  smart = TRUE,
  extensions = c("table", "autolink", "strikethrough", "tasklist")
)

# The Markdown source reserves level 1 for the document title. Shift body
# headings up one level so Word's navigation pane and TOC start at Heading 1.
replacements <- c(
  "<h2" = "<meta-h1", "</h2>" = "</meta-h1>",
  "<h3" = "<meta-h2", "</h3>" = "</meta-h2>",
  "<h4" = "<meta-h3", "</h4>" = "</meta-h3>"
)
for (from in names(replacements)) body <- gsub(from, replacements[[from]], body, fixed = TRUE)
body <- gsub("<meta-h1", "<h1", body, fixed = TRUE)
body <- gsub("</meta-h1>", "</h1>", body, fixed = TRUE)
body <- gsub("<meta-h2", "<h2", body, fixed = TRUE)
body <- gsub("</meta-h2>", "</h2>", body, fixed = TRUE)
body <- gsub("<meta-h3", "<h3", body, fixed = TRUE)
body <- gsub("</meta-h3>", "</h3>", body, fixed = TRUE)

css <- paste(
  "@page { size: Letter; margin: 1in; }",
  "body { font-family: Calibri, 'Microsoft YaHei', sans-serif; font-size: 11pt; line-height: 1.25; color: #20262e; }",
  "h1 { color: #1f4e79; font-size: 16pt; margin: 18pt 0 10pt; page-break-after: avoid; }",
  "h2 { color: #2f5f85; font-size: 13pt; margin: 14pt 0 7pt; page-break-after: avoid; }",
  "h3 { color: #334e68; font-size: 12pt; margin: 10pt 0 5pt; page-break-after: avoid; }",
  "p { margin: 0 0 6pt; }",
  "pre { font-family: Consolas, monospace; font-size: 8.5pt; line-height: 1.15; white-space: pre-wrap; word-wrap: break-word; background: #f4f6f8; border: 1px solid #d9e2ec; padding: 7pt; margin: 5pt 0 8pt; }",
  "code { font-family: Consolas, monospace; font-size: 9pt; background: #f4f6f8; }",
  "table { border-collapse: collapse; width: 100%; margin: 6pt 0 10pt; font-size: 9.5pt; }",
  "th { background: #e8eef5; color: #243b53; font-weight: bold; }",
  "th, td { border: 1px solid #b8c4ce; padding: 4pt 6pt; vertical-align: top; }",
  "blockquote { margin: 6pt 0 8pt 12pt; padding: 5pt 8pt; border-left: 3pt solid #4f81bd; background: #eef5fb; }",
  "ul, ol { margin: 2pt 0 7pt 18pt; }",
  "li { margin: 0 0 3pt; }",
  "a { color: #1f5f99; text-decoration: none; }",
  sep = "\n"
)

document <- paste0(
  "<!doctype html>\n<html><head><meta charset=\"utf-8\">\n",
  "<title>meta3level 0.6.2 Complete User Manual</title>\n",
  "<style>\n", css, "\n</style></head><body>\n",
  body,
  "\n</body></html>\n"
)

dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
writeLines(enc2utf8(document), output, useBytes = TRUE)
cat("Manual HTML written:", normalizePath(output, winslash = "/", mustWork = TRUE), "\n")
