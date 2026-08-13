# ============================================================================
# Auditable meta-analysis template using native metafor calls
# This script does not use the meta3level package.
# Replace values only in the CONFIGURATION block, then review all assumptions.
# ============================================================================

# Required package. Install packages manually before running this script.
if (!requireNamespace("metafor", quietly = TRUE)) {
  stop("Install the 'metafor' package before running this script.")
}

# CONFIGURATION ---------------------------------------------------------------
cfg <- list(
  # Input: set useSynthetic = FALSE for a real CSV/TSV/XLSX/XLS file.
  useSynthetic = TRUE,
  file = "REPLACE_WITH_FULL_PATH.csv",
  sheet = 1,
  encoding = "UTF-8",
  sep = ",",
  decimal = ".",

  # Effect type: "r", "d", "g", "or", or "custom".
  measure = "r",
  design = "independent", # for d/g: "independent" or "onegroup"
  study = "studyID",
  effect = "effectID",    # set NULL to generate IDs from source rows
  value = "r",
  n = "n",
  n1 = NULL,
  n2 = NULL,
  vi = NULL,
  se = NULL,               # OR: standard error of log(OR), not OR
  lower = NULL,            # OR confidence limit
  upper = NULL,
  conf = 0.95,
  cellA = NULL,
  cellB = NULL,
  cellC = NULL,
  cellD = NULL,
  correction = 0.5,

  # Model and reporting.
  level = "three",         # "three" or "single"
  rho = 0.60,              # used to GLS-pool effects for study-level methods
  reportScale = "auto",    # "auto", "z", "r", "g", "logor", "or", "custom"

  # Moderators. Use original column names.
  continuous = c("age", "year"),
  categorical = list(
    list(var = "design", ref = "cross-sectional", name = "Study design")
  ),
  splines = list(
    list(var = "age", dfs = 1:3, includeLinear = TRUE, name = "Age")
  ),

  # Optional analyses.
  publicationBias = FALSE,
  leaveOneEffect = TRUE,
  leaveOneStudy = TRUE,
  drawPlots = FALSE
)

# Optional programmatic override for automated testing or repeated projects.
# Example: options(runMetaAnalysisR.config = list(measure = "d", value = "d"))
cfgOverride <- getOption("runMetaAnalysisR.config", NULL)
if (!is.null(cfgOverride)) {
  if (!is.list(cfgOverride)) stop("runMetaAnalysisR.config must be a list.")
  cfg <- utils::modifyList(cfg, cfgOverride, keep.null = TRUE)
}

# HELPERS ---------------------------------------------------------------------
section <- function(title) {
  cat("\n", paste(rep("=", 78), collapse = ""), "\n", sep = "")
  cat(title, "\n")
  cat(paste(rep("=", 78), collapse = ""), "\n", sep = "")
}

requireColumns <- function(data, columns) {
  columns <- unique(columns[!vapply(columns, is.null, logical(1))])
  missing <- setdiff(columns, names(data))
  if (length(missing)) {
    stop("Missing required column(s): ", paste(missing, collapse = ", "))
  }
}

numericColumn <- function(x, name, decimal = ".") {
  text <- trimws(as.character(x))
  text[tolower(text) %in% c("", "na", "n/a", "null", "missing", ".")] <- NA
  if (decimal == ",") text <- sub(",", ".", text, fixed = TRUE)
  value <- suppressWarnings(as.numeric(text))
  bad <- !is.na(text) & !is.finite(value)
  if (any(bad)) {
    examples <- paste(utils::head(unique(text[bad]), 5), collapse = ", ")
    stop("Column '", name, "' contains nonnumeric values: ", examples)
  }
  value
}

hedgesJ <- function(df) {
  out <- rep(NA_real_, length(df))
  ok <- is.finite(df) & df > 1
  out[ok] <- exp(
    lgamma(df[ok] / 2) - 0.5 * log(df[ok] / 2) -
      lgamma((df[ok] - 1) / 2)
  )
  out
}

backTransform <- function(x, scale) {
  if (scale == "z") return(tanh(x))
  if (scale == "logor") return(exp(x))
  x
}

coefTable <- function(model, scale, allEffects = FALSE) {
  sm <- as.data.frame(stats::coef(summary(model)))
  sm$term <- rownames(sm)
  rownames(sm) <- NULL
  statisticName <- if ("tval" %in% names(sm)) "tval" else "zval"
  out <- data.frame(
    term = sm$term,
    estimateAnalysis = sm$estimate,
    se = sm$se,
    statistic = sm[[statisticName]],
    df = if ("df" %in% names(sm)) sm$df else NA_real_,
    p = sm$pval,
    ciLbAnalysis = sm$ci.lb,
    ciUbAnalysis = sm$ci.ub,
    stringsAsFactors = FALSE
  )
  transformRows <- if (allEffects) rep(TRUE, nrow(out)) else out$term == "intrcpt"
  out$estimateReported <- out$estimateAnalysis
  out$ciLbReported <- out$ciLbAnalysis
  out$ciUbReported <- out$ciUbAnalysis
  out$estimateReported[transformRows] <- backTransform(
    out$estimateAnalysis[transformRows], scale
  )
  out$ciLbReported[transformRows] <- backTransform(
    out$ciLbAnalysis[transformRows], scale
  )
  out$ciUbReported[transformRows] <- backTransform(
    out$ciUbAnalysis[transformRows], scale
  )
  out
}

fTable <- function(model) {
  if (is.null(model$QM) || !length(model$QM)) {
    stop("The model has no moderator omnibus test.")
  }
  if (!model$test %in% c("t", "knha", "hksj", "adhoc")) {
    stop("The model was not fitted with t/F inference; QM is not an F statistic.")
  }
  df1 <- if (length(model$QMdf)) model$QMdf[1] else model$m
  df2 <- if (length(model$QMdf) > 1) model$QMdf[2] else model$ddf
  data.frame(
    F = as.numeric(model$QM),
    df1 = as.numeric(df1),
    df2 = as.numeric(df2),
    p = as.numeric(model$QMp)
  )
}

typicalVi <- function(vi) {
  w <- 1 / vi
  denominator <- sum(w)^2 - sum(w^2)
  if (length(vi) < 2 || denominator <= 0) return(NA_real_)
  ((length(vi) - 1) * sum(w)) / denominator
}

multilevelI2 <- function(model) {
  sigma <- as.numeric(model$sigma2)
  if (length(sigma) < 2) sigma <- c(sigma, NA_real_)
  vTypical <- typicalVi(model$vi)
  denominator <- sum(sigma[1:2], na.rm = TRUE) + vTypical
  data.frame(
    level = c("Between studies (Level 3)",
              "Within studies (Level 2)", "Total I2"),
    variance = c(sigma[1], sigma[2], sum(sigma[1:2], na.rm = TRUE)),
    I2Percent = 100 * c(
      sigma[1], sigma[2], sum(sigma[1:2], na.rm = TRUE)
    ) / denominator
  )
}

fitThree <- function(data, mods = NULL, method = "REML",
                     sigma2 = c(NA, NA)) {
  if (nrow(data) < 4 || length(unique(data$studyID)) < 2) {
    stop("A three-level model requires at least four effects from two studies.")
  }
  if (!any(table(data$studyID) > 1)) {
    stop("A three-level model requires at least one study with repeated effects.")
  }
  args <- list(
    yi = data$yi,
    V = data$vi,
    random = stats::as.formula("~ 1 | studyID/effectID"),
    method = method,
    test = "t",
    sigma2 = sigma2,
    data = data
  )
  if (!is.null(mods)) args$mods <- mods
  do.call(metafor::rma.mv, args)
}

glsByStudy <- function(data, rho = 0.60, keep = character()) {
  if (!is.numeric(rho) || length(rho) != 1 || !is.finite(rho) ||
      rho < 0 || rho >= 1) {
    stop("rho must be one number in [0, 1).")
  }
  requireColumns(data, c("studyID", "effectID", "yi", "vi", keep))
  pieces <- split(data, data$studyID, drop = TRUE)
  rows <- lapply(pieces, function(z) {
    V <- outer(sqrt(z$vi), sqrt(z$vi)) * rho
    diag(V) <- z$vi
    Vinv <- tryCatch(solve(V), error = function(e) qr.solve(V))
    one <- rep(1, nrow(z))
    denominator <- as.numeric(crossprod(one, Vinv %*% one))
    row <- data.frame(
      studyID = as.character(z$studyID[1]),
      effectID = paste0("study_", as.character(z$studyID[1])),
      yi = as.numeric(crossprod(one, Vinv %*% z$yi) / denominator),
      vi = 1 / denominator,
      effects = nrow(z),
      stringsAsFactors = FALSE
    )
    for (column in keep) {
      values <- unique(z[[column]][!is.na(z[[column]])])
      if (length(values) > 1) {
        stop("Study '", as.character(z$studyID[1]),
             "' has conflicting values for study-level moderator '",
             column, "'.")
      }
      row[[column]] <- if (length(values)) values[1] else NA
    }
    row
  })
  out <- do.call(rbind, rows)
  out$studyID <- factor(out$studyID)
  out$effectID <- factor(out$effectID)
  out$sei <- sqrt(out$vi)
  out
}

fitSingle <- function(data, mods = NULL, method = "REML") {
  args <- list(
    yi = data$yi,
    vi = data$vi,
    method = method,
    test = "knha",
    data = data
  )
  if (!is.null(mods)) args$mods <- mods
  do.call(metafor::rma, args)
}

fitForLevel <- function(data, mods = NULL, method = "REML", level = cfg$level) {
  if (level == "three") return(fitThree(data, mods, method))
  fitSingle(data, mods, method)
}

oneSidedLrt <- function(model, data, mods = NULL) {
  if (cfg$level == "single") {
    full <- fitSingle(data, mods, method = "ML")
    reducedArgs <- list(
      yi = data$yi, vi = data$vi,
      method = "FE", test = "z", data = data
    )
    if (!is.null(mods)) reducedArgs$mods <- mods
    reduced <- do.call(metafor::rma, reducedArgs)
    statistic <- max(0, 2 * (as.numeric(logLik(full)) -
                               as.numeric(logLik(reduced))))
    return(data.frame(
      component = "Between-study variance",
      LRT = statistic, df = 1,
      pOneSided = 0.5 * pchisq(statistic, 1, lower.tail = FALSE)
    ))
  }
  reducedL3 <- fitThree(data, mods, method = model$method, sigma2 = c(0, NA))
  reducedL2 <- fitThree(data, mods, method = model$method, sigma2 = c(NA, 0))
  one <- function(reduced, label) {
    statistic <- max(0, 2 * (as.numeric(logLik(model)) -
                               as.numeric(logLik(reduced))))
    data.frame(
      component = label, LRT = statistic, df = 1,
      pOneSided = 0.5 * pchisq(statistic, 1, lower.tail = FALSE)
    )
  }
  rbind(
    one(reducedL3, "Between-study variance (Level 3)"),
    one(reducedL2, "Within-study variance (Level 2)")
  )
}

fitStats <- function(model, label) {
  ll <- logLik(model)
  parameters <- attr(ll, "df")
  k <- model$k
  aic <- AIC(model)
  aicc <- if (k > parameters + 1) {
    aic + 2 * parameters * (parameters + 1) / (k - parameters - 1)
  } else {
    NA_real_
  }
  data.frame(
    model = label,
    logLik = as.numeric(ll),
    deviance = -2 * as.numeric(ll),
    AIC = aic,
    AICc = aicc,
    BIC = BIC(model),
    parameters = parameters,
    k = k,
    stringsAsFactors = FALSE
  )
}

safeFit <- function(expr) {
  tryCatch(expr, error = function(e) {
    structure(list(message = conditionMessage(e)), class = "analysisError")
  })
}

# INPUT -----------------------------------------------------------------------
if (isTRUE(cfg$useSynthetic)) {
  raw <- data.frame(
    studyID = rep(seq_len(12), each = 2),
    effectID = rep(1:2, 12),
    r = c(-.12, -.08, -.20, -.16, -.05, -.09, -.18, -.14,
          -.10, -.07, -.22, -.15, -.06, -.11, -.17, -.13,
          -.09, -.12, -.14, -.18, -.08, -.10, -.16, -.19),
    n = rep(seq(70, 180, by = 10), each = 2),
    d = seq(0.15, 0.61, length.out = 24),
    g = seq(0.14, 0.59, length.out = 24),
    viG = rep(seq(0.025, 0.014, length.out = 12), each = 2),
    n1 = rep(seq(30, 52, by = 2), each = 2),
    n2 = rep(seq(32, 54, by = 2), each = 2),
    events1 = rep(seq(8, 19), each = 2) + rep(0:1, 12),
    nonevents1 = rep(seq(32, 43), each = 2),
    events2 = rep(seq(10, 21), each = 2),
    nonevents2 = rep(seq(30, 41), each = 2) + rep(1:0, 12),
    customYi = seq(-0.25, 0.20, length.out = 24),
    customVi = rep(seq(0.020, 0.010, length.out = 12), each = 2),
    age = rep(seq(6.5, 12, length.out = 12), each = 2),
    year = rep(2012:2023, each = 2),
    design = rep(rep(c("cross-sectional", "longitudinal"), 6), each = 2),
    stringsAsFactors = FALSE
  )
} else {
  extension <- tolower(tools::file_ext(cfg$file))
  if (extension %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Install 'readxl' to read Excel files.")
    }
    raw <- as.data.frame(readxl::read_excel(cfg$file, sheet = cfg$sheet),
                         stringsAsFactors = FALSE)
  } else if (extension %in% c("csv", "tsv", "txt")) {
    raw <- utils::read.table(
      cfg$file, header = TRUE, sep = cfg$sep,
      fileEncoding = cfg$encoding, check.names = FALSE,
      quote = "\"", comment.char = "", stringsAsFactors = FALSE
    )
  } else {
    stop("Supported input formats are CSV, TSV, TXT, XLSX, and XLS.")
  }
}

section("SOURCE DATA AUDIT")
cat("Rows =", nrow(raw), "; columns =", ncol(raw), "\n")
print(names(raw))
if (any(!nzchar(trimws(names(raw)))) || anyDuplicated(names(raw))) {
  stop("Source data contain blank or duplicate column names. Repair them first.")
}

# EFFECT-SIZE PREPARATION -----------------------------------------------------
measure <- tolower(cfg$measure)
tableInput <- measure == "or" && all(!vapply(
  list(cfg$cellA, cfg$cellB, cfg$cellC, cfg$cellD), is.null, logical(1)
))
effectColumns <- switch(
  measure,
  r = c(cfg$value, cfg$n),
  d = if (cfg$design == "independent") {
    c(cfg$value, cfg$n1, cfg$n2, cfg$vi)
  } else {
    c(cfg$value, cfg$n, cfg$vi)
  },
  g = if (!is.null(cfg$vi)) {
    c(cfg$value, cfg$vi)
  } else if (cfg$design == "independent") {
    c(cfg$value, cfg$n1, cfg$n2)
  } else {
    stop("One-group/pre-post g requires a design-specific variance column.")
  },
  or = if (tableInput) {
    c(cfg$cellA, cfg$cellB, cfg$cellC, cfg$cellD)
  } else {
    c(cfg$value, cfg$vi, cfg$se, cfg$lower, cfg$upper)
  },
  custom = c(cfg$value, cfg$vi),
  stop("Unknown cfg$measure.")
)
required <- c(cfg$study, cfg$effect, effectColumns,
              cfg$continuous,
              vapply(cfg$categorical, function(z) z$var, character(1)),
              vapply(cfg$splines, function(z) z$var, character(1)))
requireColumns(raw, required)

dat <- raw
dat$.sourceRow <- seq_len(nrow(dat))
dat$studyID <- trimws(as.character(dat[[cfg$study]]))
dat$effectID <- if (is.null(cfg$effect)) {
  paste0("effect_", dat$.sourceRow)
} else {
  trimws(as.character(dat[[cfg$effect]]))
}
dat$studyID[dat$studyID == ""] <- NA
dat$effectID[dat$effectID == ""] <- NA
dropReason <- rep("", nrow(dat))
dropReason[is.na(dat$studyID) | is.na(dat$effectID)] <- "missing ID"

scale <- switch(measure, r = "z", d = "g", g = "g",
                or = "logor", custom = "custom",
                stop("Unknown cfg$measure."))

if (measure == "r") {
  r <- numericColumn(dat[[cfg$value]], cfg$value, cfg$decimal)
  n <- numericColumn(dat[[cfg$n]], cfg$n, cfg$decimal)
  valid <- is.finite(r) & abs(r) < 1 & is.finite(n) & n > 3
  dat$yi <- ifelse(valid, atanh(r), NA_real_)
  dat$vi <- ifelse(valid, 1 / (n - 3), NA_real_)
  dropReason[dropReason == "" & !valid] <- "invalid r or n"
} else if (measure %in% c("d", "g")) {
  effect <- numericColumn(dat[[cfg$value]], cfg$value, cfg$decimal)
  knownVi <- if (!is.null(cfg$vi)) {
    numericColumn(dat[[cfg$vi]], cfg$vi, cfg$decimal)
  } else rep(NA_real_, nrow(dat))
  if (measure == "g" && !is.null(cfg$vi)) {
    dat$yi <- effect
    dat$vi <- knownVi
    valid <- is.finite(effect) & is.finite(dat$vi) & dat$vi > 0
  } else if (cfg$design == "independent") {
    n1 <- numericColumn(dat[[cfg$n1]], cfg$n1, cfg$decimal)
    n2 <- numericColumn(dat[[cfg$n2]], cfg$n2, cfg$decimal)
    J <- hedgesJ(n1 + n2 - 2)
    dat$yi <- if (measure == "d") J * effect else effect
    transformedVi <- if (measure == "d") J^2 * knownVi else knownVi
    fallbackVi <- (n1 + n2) / (n1 * n2) +
      dat$yi^2 / (2 * (n1 + n2))
    dat$vi <- ifelse(
      is.finite(transformedVi) & transformedVi > 0,
      transformedVi, fallbackVi
    )
    valid <- is.finite(effect) & n1 > 1 & n2 > 1 &
      is.finite(dat$yi) & is.finite(dat$vi) & dat$vi > 0
  } else {
    if (is.null(cfg$vi)) {
      stop("One-group/pre-post d or g requires a design-specific variance column.")
    }
    n <- numericColumn(dat[[cfg$n]], cfg$n, cfg$decimal)
    J <- hedgesJ(n - 1)
    dat$yi <- if (measure == "d") J * effect else effect
    dat$vi <- if (measure == "d") J^2 * knownVi else knownVi
    valid <- is.finite(effect) & n > 2 & is.finite(dat$yi) &
      is.finite(dat$vi) & dat$vi > 0
  }
  dropReason[dropReason == "" & !valid] <- "invalid d/g, n, or vi"
  if (any(abs(dat$yi[valid]) > 3)) {
    warning("At least one retained standardized mean difference has |g| > 3; verify it.")
  }
} else if (measure == "or") {
  if (tableInput) {
    cells <- data.frame(
      a = numericColumn(dat[[cfg$cellA]], cfg$cellA, cfg$decimal),
      b = numericColumn(dat[[cfg$cellB]], cfg$cellB, cfg$decimal),
      c = numericColumn(dat[[cfg$cellC]], cfg$cellC, cfg$decimal),
      d = numericColumn(dat[[cfg$cellD]], cfg$cellD, cfg$decimal)
    )
    valid <- apply(cells, 1, function(z) {
      all(is.finite(z)) && all(z >= 0) && all(z == round(z)) &&
        sum(z[1:2]) > 0 &&
        sum(z[3:4]) > 0 && !((z[1] == 0 && z[3] == 0) ||
                               (z[2] == 0 && z[4] == 0))
    })
    zero <- valid & apply(cells, 1, function(z) any(z == 0))
    if (any(zero) && cfg$correction <= 0) {
      stop("A positive continuity correction is required for zero-cell tables.")
    }
    adjusted <- cells
    adjusted[!valid, ] <- NA_real_
    adjusted[zero, ] <- adjusted[zero, , drop = FALSE] + cfg$correction
    dat$yi <- with(adjusted, log((a * d) / (b * c)))
    dat$vi <- with(adjusted, 1 / a + 1 / b + 1 / c + 1 / d)
  } else {
    oddsRatio <- numericColumn(dat[[cfg$value]], cfg$value, cfg$decimal)
    dat$yi <- ifelse(oddsRatio > 0, log(oddsRatio), NA_real_)
    uncertaintyRoutes <- sum(c(!is.null(cfg$vi), !is.null(cfg$se),
                               !is.null(cfg$lower) || !is.null(cfg$upper)))
    if (uncertaintyRoutes != 1) {
      stop("OR requires exactly one uncertainty route: vi, se, or both CI limits.")
    }
    if (!is.null(cfg$vi)) {
      dat$vi <- numericColumn(dat[[cfg$vi]], cfg$vi, cfg$decimal)
    } else if (!is.null(cfg$se)) {
      logSe <- numericColumn(dat[[cfg$se]], cfg$se, cfg$decimal)
      dat$vi <- logSe^2
    } else {
      if (is.null(cfg$lower) || is.null(cfg$upper)) {
        stop("Both OR confidence limits are required.")
      }
      lower <- numericColumn(dat[[cfg$lower]], cfg$lower, cfg$decimal)
      upper <- numericColumn(dat[[cfg$upper]], cfg$upper, cfg$decimal)
      zcrit <- qnorm(1 - (1 - cfg$conf) / 2)
      dat$vi <- ((log(upper) - log(lower)) / (2 * zcrit))^2
      validCi <- lower > 0 & upper > lower &
        oddsRatio >= lower & oddsRatio <= upper
      dat$vi[!validCi] <- NA_real_
    }
    valid <- oddsRatio > 0 & is.finite(dat$yi) &
      is.finite(dat$vi) & dat$vi > 0
  }
  dropReason[dropReason == "" & !valid] <- "invalid OR input"
} else {
  dat$yi <- numericColumn(dat[[cfg$value]], cfg$value, cfg$decimal)
  dat$vi <- numericColumn(dat[[cfg$vi]], cfg$vi, cfg$decimal)
  valid <- is.finite(dat$yi) & is.finite(dat$vi) & dat$vi > 0
  dropReason[dropReason == "" & !valid] <- "invalid custom yi or vi"
}

validFinal <- dropReason == "" & is.finite(dat$yi) &
  is.finite(dat$vi) & dat$vi > 0
dropReason[dropReason == "" & !validFinal] <- "invalid transformed effect"
removed <- data.frame(
  sourceRow = dat$.sourceRow[!validFinal],
  reason = dropReason[!validFinal],
  stringsAsFactors = FALSE
)
dat <- droplevels(dat[validFinal, , drop = FALSE])
dat$studyID <- factor(dat$studyID)
dat$effectID <- factor(dat$effectID)
dat$sei <- sqrt(dat$vi)

if (!nrow(dat)) stop("No valid effects remain.")
if (anyDuplicated(data.frame(dat$studyID, dat$effectID))) {
  stop("Each studyID/effectID pair must be unique.")
}

if (cfg$reportScale != "auto") {
  scale <- switch(
    tolower(cfg$reportScale),
    z = "z", r = "z", g = "g", logor = "logor", or = "logor",
    custom = "custom", stop("Unknown cfg$reportScale.")
  )
}

section("EFFECT-SIZE RETENTION AUDIT")
cat("Source rows =", nrow(raw), "\n")
cat("Retained effects k =", nrow(dat), "\n")
cat("Independent studies =", length(unique(dat$studyID)), "\n")
cat("Removed rows =", nrow(removed), "\n")
if (nrow(removed)) print(removed, row.names = FALSE)
cat("Effects per study:\n")
print(table(dat$studyID))
cat("Analysis-scale effect summary:\n")
print(summary(dat$yi))

studyCount <- length(unique(dat$studyID))
if (cfg$level == "three") {
  if (studyCount < 2 || !any(table(dat$studyID) > 1)) {
    stop("Three-level analysis requires at least two studies and repeated effects.")
  }
  modelDat <- dat
} else if (cfg$level == "single") {
  modelDat <- glsByStudy(dat, rho = cfg$rho)
} else {
  stop("cfg$level must be 'three' or 'single'.")
}

# MAIN MODEL ------------------------------------------------------------------
mainModel <- fitForLevel(modelDat)
section(if (cfg$level == "three") "THREE-LEVEL MAIN MODEL" else
          "CONVENTIONAL RANDOM-EFFECTS MAIN MODEL")
print(summary(mainModel))

section("POOLED EFFECT ON REPORTING SCALE")
print(coefTable(mainModel, scale)[1, ], row.names = FALSE)

if (cfg$level == "three") {
  section("MULTILEVEL I-SQUARED")
  print(multilevelI2(mainModel), row.names = FALSE)
} else {
  section("CONVENTIONAL HETEROGENEITY")
  qDf <- if (length(mainModel$QEdf)) mainModel$QEdf else
    mainModel$k - mainModel$p
  print(data.frame(
    k = mainModel$k,
    tau2 = mainModel$tau2,
    tau = sqrt(mainModel$tau2),
    I2Percent = mainModel$I2,
    H2 = mainModel$H2,
    Q = mainModel$QE,
    Qdf = qDf,
    Qp = mainModel$QEp
  ), row.names = FALSE)
  section("PREDICTION INTERVAL")
  prediction <- predict(mainModel)
  print(data.frame(
    estimate = backTransform(prediction$pred, scale),
    ciLb = backTransform(prediction$ci.lb, scale),
    ciUb = backTransform(prediction$ci.ub, scale),
    piLb = backTransform(prediction$pi.lb, scale),
    piUb = backTransform(prediction$pi.ub, scale)
  ), row.names = FALSE)
}

section("ONE-SIDED VARIANCE-COMPONENT LRT")
print(oneSidedLrt(mainModel, modelDat), row.names = FALSE)
cat("Reference: 0.5*chi-square(0) + 0.5*chi-square(1) boundary approximation.\n")

# CONTINUOUS MODERATORS -------------------------------------------------------
continuousResults <- list()
for (variable in cfg$continuous) {
  rawModerator <- numericColumn(dat[[variable]], variable, cfg$decimal)
  sourceMod <- dat[is.finite(rawModerator), , drop = FALSE]
  sourceMod$moderatorRaw <- rawModerator[is.finite(rawModerator)]
  if (cfg$level == "single") {
    modDat <- glsByStudy(sourceMod, rho = cfg$rho, keep = "moderatorRaw")
  } else {
    modDat <- sourceMod
  }
  if (length(unique(modDat$moderatorRaw)) < 2) {
    warning("Skipping continuous moderator '", variable,
            "': fewer than two distinct values.")
    next
  }
  center <- mean(modDat$moderatorRaw)
  modDat$moderatorC <- modDat$moderatorRaw - center
  model <- fitForLevel(modDat, ~ moderatorC)
  section(paste("CONTINUOUS MODERATOR:", variable))
  cat("k =", model$k, "; studies =", length(unique(modDat$studyID)),
      "; centering mean =", center,
      "; centered mean =", mean(modDat$moderatorC), "\n")
  print(summary(model))
  cat("\nMetafor omnibus F test:\n")
  print(fTable(model), row.names = FALSE)
  cat("\nReported-scale intercept; slope remains on analysis scale:\n")
  print(coefTable(model, scale), row.names = FALSE)
  cat("\nOne-sided variance-component LRT:\n")
  print(oneSidedLrt(model, modDat, ~ moderatorC), row.names = FALSE)
  continuousResults[[variable]] <- list(
    center = center, data = modDat, model = model, f = fTable(model)
  )
}

# CATEGORICAL MODERATORS ------------------------------------------------------
categoricalResults <- list()
for (spec in cfg$categorical) {
  variable <- spec$var
  label <- if (is.null(spec$name)) variable else spec$name
  sourceMod <- dat
  clean <- trimws(as.character(sourceMod[[variable]]))
  keep <- !is.na(clean) & nzchar(clean)
  sourceMod <- sourceMod[keep, , drop = FALSE]
  sourceMod$moderatorFactor <- factor(clean[keep])
  if (cfg$level == "single") {
    pooled <- glsByStudy(sourceMod, rho = cfg$rho,
                         keep = "moderatorFactor")
    pooled$moderatorFactor <- factor(pooled$moderatorFactor)
    modDat <- pooled
  } else {
    modDat <- sourceMod
  }
  if (!spec$ref %in% levels(modDat$moderatorFactor)) {
    stop("Reference category not found for '", variable, "': ", spec$ref)
  }
  modDat$moderatorFactor <- relevel(modDat$moderatorFactor, ref = spec$ref)
  interceptModel <- fitForLevel(modDat, ~ moderatorFactor)
  noInterceptModel <- fitForLevel(modDat, ~ 0 + moderatorFactor)
  effectWeights <- if (cfg$level == "single" && "effects" %in% names(modDat)) {
    modDat$effects
  } else {
    rep(1, nrow(modDat))
  }
  countsEffects <- aggregate(
    effectWeights, list(category = modDat$moderatorFactor), sum
  )
  names(countsEffects)[2] <- "effects"
  countsStudies <- aggregate(
    as.character(modDat$studyID),
    list(category = modDat$moderatorFactor),
    function(x) length(unique(x))
  )
  names(countsStudies)[2] <- "studies"
  section(paste("CATEGORICAL MODERATOR:", label))
  cat("Reference category =", spec$ref, "\n")
  print(merge(countsEffects, countsStudies, by = "category"), row.names = FALSE)
  cat("\nIntercept model: contrasts against reference\n")
  print(summary(interceptModel))
  cat("\nMetafor omnibus F test:\n")
  print(fTable(interceptModel), row.names = FALSE)
  cat("\nNo-intercept model: pooled effect for every category\n")
  print(summary(noInterceptModel))
  cat("\nCategory effects on reporting scale:\n")
  print(coefTable(noInterceptModel, scale, allEffects = TRUE), row.names = FALSE)
  cat("\nOne-sided variance-component LRT:\n")
  print(oneSidedLrt(interceptModel, modDat, ~ moderatorFactor), row.names = FALSE)
  categoricalResults[[label]] <- list(
    data = modDat, intercept = interceptModel,
    noIntercept = noInterceptModel, f = fTable(interceptModel)
  )
}

# SPLINE COMPARISON -----------------------------------------------------------
splineResults <- list()
for (spec in cfg$splines) {
  variable <- spec$var
  label <- if (is.null(spec$name)) variable else spec$name
  moderator <- numericColumn(dat[[variable]], variable, cfg$decimal)
  sourceMod <- dat[is.finite(moderator), , drop = FALSE]
  sourceMod$moderatorRaw <- moderator[is.finite(moderator)]
  if (cfg$level == "single") {
    splineDat <- glsByStudy(sourceMod, rho = cfg$rho, keep = "moderatorRaw")
  } else {
    splineDat <- sourceMod
  }
  center <- mean(splineDat$moderatorRaw)
  splineDat$moderatorC <- splineDat$moderatorRaw - center
  dfs <- sort(unique(as.integer(spec$dfs)))
  if (length(unique(splineDat$moderatorC)) <= max(dfs)) {
    stop("Too few distinct values for spline moderator '", variable, "'.")
  }
  models <- list()
  bases <- list()
  if (isTRUE(spec$includeLinear)) {
    models$linear <- fitForLevel(splineDat, ~ moderatorC, method = "ML")
  }
  for (df in dfs) {
    basis <- splines::ns(splineDat$moderatorC, df = df)
    basisNames <- paste0("spline", seq_len(ncol(basis)))
    modelData <- splineDat
    modelData[basisNames] <- basis
    formula <- as.formula(paste("~", paste(basisNames, collapse = " + ")))
    models[[paste0("splineDf", df)]] <- fitForLevel(
      modelData, formula, method = "ML"
    )
    bases[[paste0("splineDf", df)]] <- basis
  }
  comparison <- do.call(rbind, lapply(names(models), function(name) {
    fitStats(models[[name]], name)
  }))
  criterion <- if (any(is.finite(comparison$AICc))) comparison$AICc else
    comparison$AIC
  comparison$delta <- criterion - min(criterion, na.rm = TRUE)
  comparison$complexity <- ifelse(
    comparison$model == "linear", 1,
    as.integer(sub("splineDf", "", comparison$model))
  )
  comparison <- comparison[order(
    comparison$delta, comparison$complexity,
    comparison$model != "linear"
  ), ]
  competitive <- comparison[comparison$delta <= 2, ]
  preferred <- competitive$model[order(
    competitive$complexity,
    competitive$model != "linear",
    competitive$delta
  )][1]
  section(paste("ML SPLINE COMPARISON:", label))
  cat("All candidates use k =", nrow(splineDat), "; studies =",
      length(unique(splineDat$studyID)), "; centering mean =", center, "\n")
  print(comparison, row.names = FALSE)
  cat("Preferred parsimonious model among delta <= 2:", preferred, "\n")
  splineResults[[label]] <- list(
    data = splineDat, center = center, models = models,
    bases = bases, comparison = comparison, preferred = preferred
  )
}

# PUBLICATION-BIAS / SMALL-STUDY-EFFECT DIAGNOSTICS --------------------------
biasResults <- NULL
if (isTRUE(cfg$publicationBias)) {
  studyDat <- glsByStudy(dat, rho = cfg$rho)
  studyDat$sei <- sqrt(studyDat$vi)
  studyDat$variance <- studyDat$vi
  regressionDat <- if (cfg$level == "three") dat else studyDat
  regressionDat$sei <- sqrt(regressionDat$vi)
  regressionDat$variance <- regressionDat$vi

  pet <- fitForLevel(regressionDat, ~ sei)
  peese <- fitForLevel(regressionDat, ~ variance)
  studyModel <- metafor::rma(
    yi, vi, method = "REML", test = "knha", data = studyDat
  )
  singleEgger <- metafor::rma(
    yi, vi, mods = ~ sei, method = "REML", test = "knha",
    data = studyDat
  )
  trimfillModel <- safeFit(metafor::trimfill(studyModel))

  section(if (cfg$level == "three") "MULTILEVEL EGGER / PET" else
            "SINGLE-LEVEL EGGER / PET")
  print(summary(pet))
  print(fTable(pet), row.names = FALSE)
  cat("\nPET intercept on reporting scale:\n")
  print(coefTable(pet, scale)[1, ], row.names = FALSE)

  section(if (cfg$level == "three") "MULTILEVEL PEESE" else
            "SINGLE-LEVEL PEESE")
  print(summary(peese))
  print(fTable(peese), row.names = FALSE)
  cat("\nPEESE intercept on reporting scale:\n")
  print(coefTable(peese, scale)[1, ], row.names = FALSE)

  section("STUDY-LEVEL EGGER")
  cat("Independent studies =", nrow(studyDat), "; GLS rho =", cfg$rho, "\n")
  print(summary(singleEgger))
  print(fTable(singleEgger), row.names = FALSE)

  section("TRIM-AND-FILL SENSITIVITY ANALYSIS")
  if (inherits(trimfillModel, "analysisError")) {
    cat("Not estimated:", trimfillModel$message, "\n")
  } else {
    print(trimfillModel)
    cat("Imputed studies =", trimfillModel$k0,
        "; side =", trimfillModel$side, "\n")
    cat("Trim-and-fill pooled effect on reporting scale:\n")
    print(coefTable(trimfillModel, scale)[1, ], row.names = FALSE)
  }
  if (scale == "g") {
    cat("\nCaution: g is mechanically related to its SE/variance; interpret PET-PEESE cautiously.\n")
  }
  cat("Egger diagnoses small-study effects/funnel asymmetry, not proven publication bias.\n")
  biasResults <- list(
    studyData = studyDat, pet = pet, peese = peese,
    studyModel = studyModel, studyEgger = singleEgger,
    trimfill = trimfillModel
  )
}

# LEAVE-ONE-OUT ---------------------------------------------------------------
leaveOneOut <- function(data, unit = c("effect", "study")) {
  unit <- match.arg(unit)
  ids <- if (unit == "effect") seq_len(nrow(data)) else
    unique(as.character(data$studyID))
  rows <- lapply(ids, function(id) {
    omit <- if (unit == "effect") seq_len(nrow(data)) == id else
      as.character(data$studyID) == id
    label <- if (unit == "effect") {
      paste(as.character(data$studyID[id]), as.character(data$effectID[id]),
            sep = "::")
    } else id
    reducedRaw <- droplevels(data[!omit, , drop = FALSE])
    reduced <- if (cfg$level == "single") {
      glsByStudy(reducedRaw, rho = cfg$rho)
    } else reducedRaw
    model <- safeFit(fitForLevel(reduced))
    if (inherits(model, "analysisError")) {
      return(data.frame(
        omitted = label, omittedEffects = sum(omit),
        remainingEffects = nrow(reducedRaw),
        remainingStudies = length(unique(reducedRaw$studyID)),
        estimateAnalysis = NA, se = NA, statistic = NA, df = NA,
        p = NA, ciLbAnalysis = NA, ciUbAnalysis = NA,
        estimateReported = NA, ciLbReported = NA, ciUbReported = NA,
        error = model$message, stringsAsFactors = FALSE
      ))
    }
    tab <- coefTable(model, scale)[1, ]
    data.frame(
      omitted = label, omittedEffects = sum(omit),
      remainingEffects = nrow(reducedRaw),
      remainingStudies = length(unique(reducedRaw$studyID)),
      estimateAnalysis = tab$estimateAnalysis,
      se = tab$se, statistic = tab$statistic, df = tab$df,
      p = tab$p, ciLbAnalysis = tab$ciLbAnalysis,
      ciUbAnalysis = tab$ciUbAnalysis,
      estimateReported = tab$estimateReported,
      ciLbReported = tab$ciLbReported,
      ciUbReported = tab$ciUbReported,
      error = NA_character_, stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

effectLeave <- NULL
studyLeave <- NULL
if (isTRUE(cfg$leaveOneEffect)) {
  effectLeave <- leaveOneOut(dat, "effect")
  section("LEAVE-ONE-EFFECT-OUT")
  print(effectLeave, row.names = FALSE)
}
if (isTRUE(cfg$leaveOneStudy)) {
  studyLeave <- leaveOneOut(dat, "study")
  section("LEAVE-ONE-STUDY-OUT")
  print(studyLeave, row.names = FALSE)
}

# PLOTS -----------------------------------------------------------------------
if (isTRUE(cfg$drawPlots)) {
  metafor::forest(mainModel, main = "Meta-analysis", xlab = "Effect size")

  if (length(continuousResults)) {
    first <- continuousResults[[1]]
    x <- seq(min(first$data$moderatorRaw), max(first$data$moderatorRaw),
             length.out = 200)
    pred <- predict(first$model, newmods = x - first$center)
    plot(first$data$moderatorRaw, first$data$yi,
         pch = 16, col = "grey70", xlab = names(continuousResults)[1],
         ylab = "Effect on analysis scale", main = "Linear moderator")
    lines(x, pred$pred, lwd = 2)
    lines(x, pred$ci.lb, lty = 3, col = "grey40")
    lines(x, pred$ci.ub, lty = 3, col = "grey40")
  }

  if (!is.null(biasResults)) {
    metafor::funnel(
      biasResults$studyModel,
      main = "Funnel plot before trim-and-fill",
      pch = 16, col = "black"
    )
  }

  if (length(splineResults)) {
    firstSpline <- splineResults[[1]]
    x <- seq(min(firstSpline$data$moderatorRaw),
             max(firstSpline$data$moderatorRaw), length.out = 250)
    xCentered <- x - firstSpline$center
    selected <- firstSpline$preferred
    selectedModel <- firstSpline$models[[selected]]
    if (selected == "linear") {
      pred <- predict(selectedModel, newmods = xCentered)
    } else {
      newBasis <- predict(firstSpline$bases[[selected]], newx = xCentered)
      pred <- predict(selectedModel, newmods = newBasis)
    }
    plot(firstSpline$data$moderatorRaw,
         backTransform(firstSpline$data$yi, scale),
         pch = 16, col = "grey75",
         xlab = names(splineResults)[1], ylab = "Effect on reporting scale",
         main = paste("Selected nonlinear model:", selected))
    lines(x, backTransform(pred$pred, scale), lwd = 2)
    lines(x, backTransform(pred$ci.lb, scale), lty = 3, col = "grey40")
    lines(x, backTransform(pred$ci.ub, scale), lty = 3, col = "grey40")
  }

  plotLeave <- function(table, title, xlab) {
    ok <- is.finite(table$estimateReported)
    plot(seq_len(nrow(table))[ok], table$estimateReported[ok],
         type = "o", pch = 16, col = "black",
         xlab = xlab, ylab = "Pooled effect", main = title)
    abline(h = coefTable(mainModel, scale)$estimateReported[1],
           col = "red", lwd = 2)
  }
  if (!is.null(effectLeave)) {
    plotLeave(effectLeave, "Leave-one-effect-out sensitivity analysis",
              "Left-out effect index")
  }
  if (!is.null(studyLeave)) {
    plotLeave(studyLeave, "Leave-one-study-out sensitivity analysis",
              "Left-out study index")
  }
}

# REPRODUCIBILITY -------------------------------------------------------------
section("ASSUMPTIONS")
cat("Effect measure =", cfg$measure, "; analysis scale =", scale, "\n")
cat("Analysis level =", cfg$level, "\n")
cat("Study-level GLS rho =", cfg$rho, "\n")
cat("Continuous moderators were centered within their retained samples.\n")
cat("Categorical moderators used intercept and no-intercept parameterizations.\n")
cat("Spline candidates used identical complete cases and ML.\n")
cat("Three-level models used diagonal sampling variances unless this script was manually extended with a V matrix.\n")

section("SESSION INFORMATION")
print(sessionInfo())
