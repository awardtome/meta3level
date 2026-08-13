args <- commandArgs(trailingOnly = TRUE)

manual <- if (length(args)) args[[1]] else "USER_MANUAL.zh-CN.md"
if (!file.exists(manual)) {
  stop("Manual not found: ", manual, call. = FALSE)
}

lines <- readLines(manual, warn = FALSE, encoding = "UTF-8")
starts <- grep("^```[Rr][[:space:]]*$", lines)

if (!length(starts)) {
  stop("No fenced R code blocks were found in: ", manual, call. = FALSE)
}

blocks <- vector("list", length(starts))
block_lines <- integer(length(starts))

for (i in seq_along(starts)) {
  start <- starts[[i]]
  candidates <- which(seq_along(lines) > start & grepl("^```[[:space:]]*$", lines))
  if (!length(candidates)) {
    stop("Unclosed R code fence starting at line ", start, call. = FALSE)
  }
  end <- candidates[[1]]
  blocks[[i]] <- if (end > start + 1L) lines[(start + 1L):(end - 1L)] else character()
  block_lines[[i]] <- start + 1L
}

failures <- list()
for (i in seq_along(blocks)) {
  code <- paste(blocks[[i]], collapse = "\n")
  parsed <- tryCatch(
    parse(text = code, keep.source = TRUE),
    error = function(e) e
  )
  if (inherits(parsed, "error")) {
    failures[[length(failures) + 1L]] <- data.frame(
      block = i,
      starts_at_line = block_lines[[i]],
      message = conditionMessage(parsed),
      stringsAsFactors = FALSE
    )
  }
}

cat("Manual:", normalizePath(manual, winslash = "/", mustWork = TRUE), "\n")
cat("R code blocks:", length(blocks), "\n")

if (length(failures)) {
  failure_table <- do.call(rbind, failures)
  print(failure_table, row.names = FALSE)
  stop(nrow(failure_table), " R code block(s) failed to parse.", call. = FALSE)
}

cat("Status: all R code blocks parsed successfully.\n")
