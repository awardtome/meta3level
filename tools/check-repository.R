options(warn = 1)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
failures <- character()

isRepositoryArtifact <- function(paths) {
  normalized <- gsub("\\\\", "/", paths)
  grepl("(^|/)([.]git|[^/]+[.]Rcheck)(/|$)", normalized, perl = TRUE)
}

fail <- function(message) {
  failures <<- c(failures, message)
  message("FAIL: ", message)
}

pass <- function(message) message("PASS: ", message)

description <- read.dcf(file.path(root, "DESCRIPTION"))
version <- unname(description[1, "Version"])
if (!grepl("^[0-9]+[.][0-9]+[.][0-9]+$", version)) {
  fail("DESCRIPTION Version is not semantic x.y.z format.")
} else {
  pass(paste("DESCRIPTION version", version))
}

rFiles <- list.files(
  root,
  pattern = "[.][Rr]$",
  recursive = TRUE,
  full.names = TRUE
)
rFiles <- rFiles[!isRepositoryArtifact(rFiles)]
parseErrors <- vapply(rFiles, function(path) {
  tryCatch({
    parse(file = path)
    ""
  }, error = function(error) conditionMessage(error))
}, character(1))
if (any(nzchar(parseErrors))) {
  for (path in names(parseErrors)[nzchar(parseErrors)]) {
    fail(paste("R parse error in", path, ":", parseErrors[[path]]))
  }
} else {
  pass(paste(length(rFiles), "R files parsed"))
}

skillPath <- file.path(root, "skills", "run-meta-analysis-r", "SKILL.md")
skill <- readLines(skillPath, warn = FALSE, encoding = "UTF-8")
if (!identical(skill[c(1, 4)], c("---", "---"))) {
  fail("SKILL.md must have a three-line YAML frontmatter block.")
} else {
  name <- sub("^name:[[:space:]]*", "", skill[2])
  descriptionText <- sub("^description:[[:space:]]*", "", skill[3])
  if (!grepl("^[a-z0-9]+(-[a-z0-9]+)*$", name) || nchar(name) > 64) {
    fail("Skill name is not valid hyphen-case or exceeds 64 characters.")
  }
  if (!nzchar(descriptionText) || nchar(descriptionText) > 1024 ||
      grepl("[<>]", descriptionText)) {
    fail("Skill description is empty, too long, or contains angle brackets.")
  }
  if (!length(failures)) pass("Skill frontmatter")
}

markdown <- list.files(
  root,
  pattern = "[.]md$",
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE
)
markdown <- markdown[!isRepositoryArtifact(markdown)]
linkPattern <- "!?\\[[^]]*\\]\\(([^)]+)\\)"
for (path in markdown) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  matches <- regmatches(lines, gregexpr(linkPattern, lines, perl = TRUE))
  links <- unlist(lapply(matches, function(items) {
    if (!length(items) || identical(items, "")) return(character())
    sub(linkPattern, "\\1", items, perl = TRUE)
  }), use.names = FALSE)
  links <- sub("[[:space:]]+['\"].*$", "", links)
  links <- sub("#.*$", "", links)
  links <- links[nzchar(links)]
  links <- links[!grepl("^(https?|mailto):", links, ignore.case = TRUE)]
  for (link in links) {
    target <- normalizePath(
      file.path(dirname(path), utils::URLdecode(link)),
      winslash = "/",
      mustWork = FALSE
    )
    if (!file.exists(target)) {
      fail(paste("Broken local Markdown link in", path, "->", link))
    }
  }
}
if (!any(grepl("Broken local Markdown link", failures, fixed = TRUE))) {
  pass(paste(length(markdown), "Markdown files have valid local links"))
}

namespaceLines <- readLines(file.path(root, "NAMESPACE"), warn = FALSE,
                            encoding = "UTF-8")
exportLines <- grep("^export\\(m3[[:alnum:]]+\\)$", namespaceLines,
                    value = TRUE)
publicFunctions <- sub("^export\\(([^)]+)\\)$", "\\1", exportLines)
referenceFiles <- c(
  "FUNCTION_REFERENCE.en.md",
  "FUNCTION_REFERENCE.zh-CN.md",
  "USER_MANUAL.en.md",
  "USER_MANUAL.zh-CN.md"
)
for (relative in referenceFiles) {
  path <- file.path(root, relative)
  if (!file.exists(path)) {
    fail(paste("Missing public-function documentation:", relative))
    next
  }
  content <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
                   collapse = "\n")
  missingFunctions <- publicFunctions[!vapply(publicFunctions, function(fun) {
    grepl(paste0("`", fun, "()`"), content, fixed = TRUE)
  }, logical(1))]
  if (length(missingFunctions)) {
    fail(paste(relative, "does not document exported function(s):",
               paste(missingFunctions, collapse = ", ")))
  }
}
if (!any(grepl("public-function documentation|does not document exported",
               failures))) {
  pass(paste(length(publicFunctions),
             "exported functions covered by both manuals and quick references"))
}

allTextFiles <- list.files(
  root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE
)
allTextFiles <- allTextFiles[file.info(allTextFiles)$isdir %in% FALSE]
allTextFiles <- allTextFiles[!isRepositoryArtifact(allTextFiles)]
allTextFiles <- allTextFiles[!grepl("[.](rds|xlsx|xls|png|jpg|jpeg|zip|gz)$",
                                   allTextFiles, ignore.case = TRUE)]
placeholderPattern <- paste(
  paste0("Meta", " Analyst"),
  paste0("analyst", "@example[.]com"),
  paste0("YOUR-GITHUB", "-USERNAME"),
  paste0("https://github.com/", "OWNER", "/meta3level"),
  paste0('"', "OWNER", "/meta3level", '"'),
  sep = "|"
)
for (path in allTextFiles) {
  content <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
                   collapse = "\n")
  if (grepl(placeholderPattern, content)) {
    fail(paste("Release identity placeholder in", path))
  }
}
if (!any(grepl("Release identity placeholder", failures,
               fixed = TRUE))) {
  pass("No release identity placeholders remain")
}

if (length(failures)) {
  stop(length(failures), " repository check(s) failed.", call. = FALSE)
}

cat("\nALL_REPOSITORY_CHECKS_PASSED\n")
