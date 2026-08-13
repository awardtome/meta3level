template <- file.path(
  "skills", "run-meta-analysis-r", "assets", "native-metafor-template.R"
)
if (!file.exists(template)) stop("Native template not found: ", template)

base <- list(
  useSynthetic = TRUE,
  continuous = character(),
  categorical = NULL,
  splines = NULL,
  publicationBias = FALSE,
  leaveOneEffect = FALSE,
  leaveOneStudy = FALSE,
  drawPlots = FALSE
)

cases <- list(
  correlationThree = list(
    measure = "r", value = "r", n = "n", level = "three"
  ),
  independentDThree = list(
    measure = "d", design = "independent", value = "d",
    n = NULL, n1 = "n1", n2 = "n2", vi = NULL, level = "three"
  ),
  precomputedGThree = list(
    measure = "g", design = "independent", value = "g",
    n = NULL, n1 = NULL, n2 = NULL, vi = "viG", level = "three"
  ),
  oddsRatioThree = list(
    measure = "or", value = NULL, n = NULL,
    cellA = "events1", cellB = "nonevents1",
    cellC = "events2", cellD = "nonevents2", level = "three"
  ),
  customThree = list(
    measure = "custom", value = "customYi", vi = "customVi",
    n = NULL, level = "three"
  ),
  correlationSingle = list(
    measure = "r", value = "r", n = "n", level = "single", rho = 0.60
  )
)

for (name in names(cases)) {
  cat("\n--- smoke case:", name, "---\n")
  options(runMetaAnalysisR.config = utils::modifyList(base, cases[[name]],
                                                       keep.null = TRUE))
  environment <- new.env(parent = globalenv())
  sys.source(template, envir = environment)
  stopifnot(inherits(environment$mainModel, "rma"))
  stopifnot(nrow(environment$dat) == 24)
  stopifnot(length(unique(environment$dat$studyID)) == 12)
}

options(runMetaAnalysisR.config = NULL)
cat("\nALL_NATIVE_TEMPLATE_SMOKE_TESTS_PASSED\n")
