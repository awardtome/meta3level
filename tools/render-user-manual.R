args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) {
  stop("Usage: Rscript render-user-manual.R manual.pdf output-directory", call. = FALSE)
}

pdf <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
output <- args[[2]]
dir.create(output, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("pdftools", quietly = TRUE) ||
    !requireNamespace("png", quietly = TRUE)) {
  stop("Packages 'pdftools' and 'png' are required to render the manual.", call. = FALSE)
}

old <- list.files(output, pattern = "^(page|contact)-.*[.]png$", full.names = TRUE)
if (length(old)) unlink(old)

page_count <- pdftools::pdf_info(pdf)$pages
page_files <- file.path(output, sprintf("page-%02d.png", seq_len(page_count)))
pdftools::pdf_convert(pdf, format = "png", dpi = 110, filenames = page_files)
page_files <- page_files[file.exists(page_files)]

pages_per_sheet <- 9L
sheet_count <- ceiling(length(page_files) / pages_per_sheet)
contact_files <- file.path(output, sprintf("contact-%02d.png", seq_len(sheet_count)))

for (sheet in seq_len(sheet_count)) {
  first <- (sheet - 1L) * pages_per_sheet + 1L
  last <- min(sheet * pages_per_sheet, length(page_files))
  indices <- first:last

  grDevices::png(contact_files[[sheet]], width = 1800, height = 2340,
                 res = 140, bg = "white")
  grid::grid.newpage()
  layout <- grid::grid.layout(
    3, 3,
    widths = rep(grid::unit(1, "null"), 3),
    heights = rep(grid::unit(1, "null"), 3)
  )
  grid::pushViewport(grid::viewport(layout = layout))

  for (position in seq_along(indices)) {
    page <- indices[[position]]
    row <- (position - 1L) %/% 3L + 1L
    column <- (position - 1L) %% 3L + 1L
    image <- png::readPNG(page_files[[page]])

    grid::pushViewport(grid::viewport(layout.pos.row = row,
                                      layout.pos.col = column))
    grid::grid.rect(gp = grid::gpar(fill = "white", col = "#B8C4CE"))
    grid::grid.raster(image, width = grid::unit(0.92, "npc"),
                      height = grid::unit(0.88, "npc"))
    grid::grid.text(
      sprintf("Page %d", page),
      y = grid::unit(0.975, "npc"),
      gp = grid::gpar(fontsize = 10, fontface = "bold", col = "#1F4E79")
    )
    grid::popViewport()
  }

  grid::popViewport()
  grDevices::dev.off()
}

cat("Rendered pages:", length(page_files), "\n")
cat("Contact sheets:", length(contact_files), "\n")
cat("Output:", normalizePath(output, winslash = "/", mustWork = TRUE), "\n")
