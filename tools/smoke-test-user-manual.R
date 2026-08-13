args <- commandArgs(trailingOnly = TRUE)
package_root <- if (length(args)) args[[1]] else normalizePath(".", winslash = "/")
example_file <- file.path(package_root, "inst", "extdata", "example_correlations.csv")

if (!requireNamespace("meta3level", quietly = TRUE)) {
  stop("Install meta3level before running this smoke test.", call. = FALSE)
}

raw <- meta3level::m3read(example_file)
age_numeric <- suppressWarnings(as.numeric(raw$age))
raw$age_percent <- paste0(round(age_numeric / max(age_numeric) * 100, 1), "%")

dat <- meta3level::m3prep(
  raw,
  measure = "r",
  study = "studyID",
  effect = "effectID",
  value = "r",
  n = "n"
)

main <- meta3level::m3fit(dat, method = "REML", f = TRUE)
stopifnot(inherits(main, "rma.mv"))
stopifnot(nrow(meta3level::m3effect(main)) == 1L)
stopifnot(nrow(meta3level::m3i2(main)) == 3L)
stopifnot(nrow(meta3level::m3lrt(main)) == 2L)

age <- meta3level::m3cont(dat, "age", name = "Age")
stopifnot(inherits(age, "meta3_continuous"))
stopifnot(all(c("F", "df1", "df2", "p") %in% names(age$f_test)))
stopifnot(abs(mean(age$data$moderator_c)) < 1e-10)

design <- meta3level::m3group(
  dat,
  "design",
  ref = "cross-sectional",
  name = "Design"
)
stopifnot(inherits(design, "meta3_categorical"))
stopifnot(nrow(design$counts_effects) == 2L)
stopifnot(nrow(design$counts_studies) == 2L)
stopifnot(nrow(design$group_effects) == 2L)

curve <- meta3level::m3spline(
  dat,
  "age",
  df = 1:3,
  linear = TRUE,
  name = "Age curve"
)
stopifnot(inherits(curve, "meta3_splines"))
stopifnot(all(c("linear", "spline_df1", "spline_df2", "spline_df3") %in%
                curve$comparison$model))

bias <- meta3level::m3bias(dat, extra = FALSE, level = "three")
stopifnot(inherits(bias, "meta3_publication_bias"))
stopifnot(all(c("F", "df1", "df2", "p") %in% names(bias$pet_f)))
stopifnot(all(c("F", "df1", "df2", "p") %in% names(bias$peese_f)))

loo_effect <- meta3level::m3leave(dat, by = "effect")
loo_study <- meta3level::m3leave(dat, by = "study")
stopifnot(nrow(loo_effect$results) == nrow(dat))
stopifnot(nrow(loo_study$results) == length(unique(dat$studyID)))

single <- meta3level::m3fit(dat, level = "single", rho = 0.60)
stopifnot(inherits(single, "rma.uni"))
stopifnot(nrow(single$meta3_data) == length(unique(dat$studyID)))

workflow <- meta3level::m3run(
  dat,
  cont = c("age", "year"),
  groups = list(list(var = "design", ref = "cross-sectional", name = "Design")),
  spline = list(list(var = "age", df = 1:3, linear = TRUE, name = "Age curve")),
  bias = FALSE,
  leave = FALSE,
  show = FALSE
)
stopifnot(identical(names(workflow),
                    c("main", "cont", "groups", "spline", "bias",
                      "effectleave", "studyleave")))

plot_file <- tempfile(fileext = ".pdf")
grDevices::pdf(plot_file, width = 8, height = 6)
invisible(meta3level::m3plot(age))
invisible(meta3level::m3plot(curve, models = c("linear", "spline_df3"),
                            show_ci = "spline_df3"))
invisible(meta3level::m3plot(loo_effect))
grDevices::dev.off()
stopifnot(file.exists(plot_file), file.info(plot_file)$size > 0)
unlink(plot_file)

d_raw <- data.frame(
  study = rep(seq_len(6), each = 2),
  effect = rep(seq_len(2), 6),
  d = seq(0.20, 0.75, length.out = 12),
  n1 = rep(c(30, 40, 50, 60, 70, 80), each = 2),
  n2 = rep(c(32, 42, 52, 62, 72, 82), each = 2)
)
d_dat <- meta3level::m3prep(
  d_raw, measure = "d", design = "independent",
  study = "study", effect = "effect", value = "d", n1 = "n1", n2 = "n2"
)
stopifnot(identical(attr(d_dat, "meta3_scale"), "g"))

or_raw <- data.frame(
  study = rep(seq_len(6), each = 2),
  effect = rep(seq_len(2), 6),
  a = rep(c(10, 12, 14, 16, 18, 20), each = 2),
  b = rep(c(30, 32, 34, 36, 38, 40), each = 2),
  c = rep(c(8, 9, 10, 11, 12, 13), each = 2),
  d = rep(c(32, 35, 38, 41, 44, 47), each = 2)
)
or_dat <- meta3level::m3prep(
  or_raw, measure = "or", study = "study", effect = "effect",
  cellA = "a", cellB = "b", cellC = "c", cellD = "d"
)
stopifnot(identical(attr(or_dat, "meta3_scale"), "logor"))

cat("User manual smoke test: PASS\n")
cat("Three-level, single-level, moderators, splines, bias, leave-one-out, plots, d-to-g, and OR paths completed.\n")
