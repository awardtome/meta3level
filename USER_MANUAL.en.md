# meta3level 0.6.2 Complete English User Manual

## 1. Purpose and scope

`meta3level` runs three-level and conventional random-effects meta-analysis in
R. It is not a new statistical estimator. It organizes established procedures
from `metafor` and related packages into short, auditable, reproducible `m3*`
functions.

The package supports:

- correlations (`r`);
- Cohen's `d` and Hedges' `g`;
- odds ratios (`OR`);
- researcher-supplied `yi` and sampling variance `vi`;
- three-level main effects, multilevel I-squared, and one-sided variance LRTs;
- continuous, categorical, and natural-spline moderators;
- conventional random-effects models with within-study GLS pooling;
- Egger, PET-PEESE, trim-and-fill, and supplementary bias diagnostics;
- leave-one-effect-out and leave-one-study-out sensitivity analyses;
- forest, moderator, spline, funnel, and leave-one-out plots; and
- complete console reports, underlying R audit code, and installed source code.

## 2. Installation

### 2.1 Install from GitHub

```r
install.packages("remotes")
remotes::install_github(
  "awardtome/meta3level",
  dependencies = NA,
  upgrade = "never"
)
library(meta3level)
```

### 2.2 Install from the Release source archive

```r
install.packages("metafor")
install.packages(
  "meta3level_0.6.2.tar.gz",
  repos = NULL,
  type = "source"
)
library(meta3level)
```

In RStudio, you can also choose **Tools > Install Packages > Install from:
Package Archive File**, then select the `.tar.gz` file.

### 2.3 Optional dependencies

```r
install.packages(c(
  "readxl",    # Excel import
  "openxlsx",  # Excel export
  "meta",      # supporting objects for Copas analyses
  "metasens",  # Copas
  "puniform",  # p-uniform
  "zcurve"     # z-curve
))
```

Optional packages are needed only when their corresponding feature is called.
The core model workflow primarily requires `metafor`.

### 2.4 Verify the installation

```r
library(meta3level)
packageVersion("meta3level")
help(package = "meta3level")
```

The expected version is `0.6.2`.

## 3. Minimal workflow

Every analysis follows four stages: read, prepare, analyze, and extract or
plot.

```r
library(meta3level)

file <- system.file(
  "extdata", "example_correlations.csv",
  package = "meta3level"
)
raw <- m3read(file)

dat <- m3prep(
  raw,
  measure = "r",
  study = "studyID",
  effect = "effectID",
  value = "r",
  n = "n"
)

result <- m3run(
  dat,
  cont = c("age", "year"),
  groups = list(
    var = "design",
    ref = "cross-sectional",
    name = "Study design"
  ),
  spline = list(
    var = "age",
    df = 1:3,
    name = "Age"
  ),
  bias = FALSE,
  leave = TRUE,
  level = "three",
  show = TRUE,
  keep = TRUE,
  code = FALSE
)
```

`show = TRUE` prints the complete result in the console. With `keep = TRUE`,
failure of an optional analysis does not stop other optional components; the
reason is stored in that component's `$message`. Failure of the main model
always stops the workflow.

## 4. Coding and data rules

### 4.1 What one row represents

One row should represent one effect size. At minimum, provide:

| Field | Requirement |
|---|---|
| Study ID | A statistically independent sample, not merely a publication number. |
| Effect ID | Unique within study; it can be generated from source row numbers if absent. |
| Effect input | `r`, `d`, `g`, `OR`, a 2 x 2 table, or custom `yi`. |
| Uncertainty input | Sample size, group sizes, CI, SE, 2 x 2 table, or `vi`. |

If one article reports two independent samples, use two study IDs. If the same
sample reports multiple outcomes, the rows share a study ID but use different
effect IDs.

### 4.2 When a three-level model is appropriate

A three-level model requires at least two independent studies and at least one
study contributing multiple effects. A stronger application has multiple
studies with repeated effects. When each study contributes only one effect,
use `level = "single"`.

### 4.3 Missing and invalid values

- Do not use zero to represent missingness unless zero is a real value.
- Each `studyID + effectID` combination must be unique.
- Correlations require `abs(r) < 1` and `n > 3`.
- Sampling variances must be positive.
- Continuous columns must not contain unexplained text.
- The value supplied to `ref` must exactly match an observed category.

`m3prep()` reports or warns about invalid rows that are removed. Retain this
screening information in the analysis record.

### 4.4 Percentage variables

Variables such as the proportion of women can use proportions from 0 to 1 or
percentage points from 0 to 100, but the column should use one consistent
scale. The package recognizes some values containing `%`. If a value such as
`1` is ambiguous between 1% and 100%, the function stops and asks the
researcher to standardize the scale.

## 5. Complete simple guide to all public functions

`meta3level` exports 18 functions. This chapter explains the purpose, usual
input, key output, and main caution for each function.

### 5.1 Function overview

| Function | What it does |
|---|---|
| `m3read()` | Reads delimited text or Excel coding files. |
| `m3prep()` | Converts reported statistics into model-ready `yi` and `vi`. |
| `m3fit()` | Fits a three-level or conventional random-effects model. |
| `m3effect()` | Extracts the intercept/overall effect and reporting-scale CI. |
| `m3ftest()` | Extracts the moderator omnibus F test. |
| `m3i2()` | Calculates multilevel or conventional heterogeneity. |
| `m3lrt()` | Tests variance components with one-sided boundary LRTs. |
| `m3cont()` | Analyzes one centered continuous moderator. |
| `m3group()` | Analyzes one categorical moderator and category-specific effects. |
| `m3spline()` | Compares linear and natural-spline moderator models using ML. |
| `m3study()` | Pools dependent effects to one effect per study. |
| `m3bias()` | Runs Egger/PET-PEESE and supplementary bias diagnostics. |
| `m3leave()` | Runs leave-one-effect-out or leave-one-study-out. |
| `m3run()` | Runs the complete selected workflow. |
| `m3plot()` | Draws the correct plot for a package result. |
| `m3report()` | Prints a complete result again. |
| `m3code()` | Generates executable underlying-package audit code. |
| `m3source()` | Displays the exact installed function implementation. |

### 5.2 `m3read()`

Use `m3read()` to import CSV, TSV, TXT, XLSX, or XLS data.

```r
raw <- m3read("coding-file.xlsx", sheet = 1)
```

The most important arguments are `file`, `sheet`, `encoding`, and `decimal`.
The result is a data frame. Import details and repaired duplicate-column names
are stored in `attr(raw, "meta3_source")`. Always inspect `names(raw)` after
reading.

### 5.3 `m3prep()`

Use `m3prep()` to prepare correlations, standardized mean differences, odds
ratios, or custom effects.

```r
dat <- m3prep(
  raw, measure = "r",
  study = "studyID", effect = "effectID",
  value = "r", n = "n"
)
```

The function returns standardized `studyID`, `effectID`, `yi`, and `vi`
columns while retaining relevant source columns. The main caution is that `vi`
must be a variance, not a standard error.

### 5.4 `m3fit()`

Use `m3fit()` for the main model or a manually specified moderator formula.

```r
main_model <- m3fit(dat, level = "three", f = TRUE)
age_model <- m3fit(dat, mods = ~ age, level = "three", f = TRUE)
```

The result is a fitted `metafor` model. `f = TRUE` requests t inference for
coefficients and an F reference distribution for moderator omnibus tests.
`level = "single"` pools dependent effects by study using `rho` before fitting
a conventional model.

### 5.5 `m3effect()`

```r
overall <- m3effect(main_model)
```

This function returns a compact estimate, SE, test, p value, and confidence
interval table. Correlations and ORs are transformed back to r and OR for
reporting. For a moderator model, the result is the intercept rather than an
unconditional pooled effect.

### 5.6 `m3ftest()`

```r
moderator_test <- m3ftest(age_model)
```

This function returns F, numerator df, denominator df, and p. Use it only for a
model fitted with t/F inference. The underlying `metafor` object may still use
the historical field name `$QM` for the statistic.

### 5.7 `m3i2()`

```r
heterogeneity <- m3i2(main_model)
```

For a three-level model, the output separates study-level (Level 3),
within-study effect-level (Level 2), and total I-squared. For a conventional
model it returns single-level heterogeneity. A zero variance is a valid
boundary estimate and should not be altered manually.

### 5.8 `m3lrt()`

```r
variance_tests <- m3lrt(main_model)
```

The function performs one-sided boundary likelihood-ratio tests for variance
components. These tests address heterogeneity, not the significance of the
pooled effect or moderator.

### 5.9 `m3cont()`

```r
age_result <- m3cont(dat, var = "age", name = "Mean age")
```

The function uses complete cases for that moderator, centers the variable at
their mean, and fits an intercept model. Key outputs are `$center`,
`$coefficients`, `$f_test`, `$i2`, and `$lrt`. Continuous moderators do not
receive a no-intercept model. Correlation slopes remain on Fisher's-z scale and
OR slopes remain on log(OR) scale.

### 5.10 `m3group()`

```r
design_result <- m3group(
  dat,
  var = "design",
  ref = "cross-sectional",
  name = "Study design"
)
```

The function fits a reference-group contrast model and a no-intercept model
containing the pooled effect for every category. Key outputs are
`$counts_effects`, `$counts_studies`, `$contrasts`, `$group_effects`, and
`$f_test`.

### 5.11 `m3spline()`

```r
curve_result <- m3spline(
  dat, var = "age", df = 1:3,
  linear = TRUE, name = "Age"
)
```

All candidates use identical complete cases and ML estimation. The comparison
includes log likelihood, AIC, AICc, BIC, and delta values. Key outputs are
`$comparison`, `$minimum_ic_model`, `$best_model`, and `$models`. Do not
increase df repeatedly to search for significance.

### 5.12 `m3study()`

```r
study_data <- m3study(dat, rho = 0.60, keep = c("age", "design"))
```

This function pools multiple dependent effects into one effect per study.
`rho` is an assumed within-study sampling correlation and should be varied in
sensitivity analyses. Variables in `keep` must be constant within each study.

### 5.13 `m3bias()`

```r
bias_result <- m3bias(
  dat, rho = 0.60, extra = TRUE,
  direction = "auto", level = "three"
)
```

Core output includes PET and PEESE coefficients/F tests, the decision rule, and
the selected adjusted intercept. When dependencies and data permit,
supplementary output includes study-level Egger, trim-and-fill, Begg,
fail-safe N, selection models, Copas, p-uniform, and p-curve. A significant
Egger result indicates a small-study effect or funnel asymmetry, not definitive
proof of publication bias.

### 5.14 `m3leave()`

```r
effect_loo <- m3leave(dat, by = "effect")
study_loo <- m3leave(dat, by = "study")
```

The result contains `$full_effect` and `$results`. Each row reports the omitted
ID, effects removed, effects and studies remaining, estimate, p value,
confidence interval, and any fitting error.

### 5.15 `m3run()`

```r
result <- m3run(
  dat,
  cont = c("age", "year"),
  groups = list(
    list(var = "design", ref = "cross-sectional", name = "Study design")
  ),
  bias = FALSE,
  leave = TRUE,
  show = TRUE,
  keep = TRUE
)
```

Use this function for a complete automated workflow. The top-level components
are `$main`, `$cont`, `$groups`, `$spline`, `$bias`, `$effectleave`, and
`$studyleave`.

### 5.16 `m3plot()`

```r
m3plot(result, "forest")
m3plot(result, "cont", name = "age")
m3plot(result, "effect")
m3plot(result, "study")
```

The function dispatches to the appropriate forest, moderator, spline, funnel,
or sensitivity plot. Select among multiple moderators with `name` or `index`.
Additional graphical options are supplied through `...`.

### 5.17 `m3report()`

```r
m3report(result)
m3report(result, code = TRUE)
```

Use this function to print an existing result again. `code = TRUE` appends the
underlying-package audit code.

### 5.18 `m3code()`

```r
m3code(result)
m3code(result, file = "analysis-audit.R")
```

This function generates executable R code that calls underlying packages
directly. Saving to a file also creates a matching `_data.rds` snapshot. Keep
the script and snapshot together and inspect the snapshot before sharing it.

### 5.19 `m3source()`

```r
m3source("m3bias")
m3source("all", print = FALSE, file = "meta3level-source.R")
```

Use this function to display or save the exact installed function definitions.
The `fun` argument can be one function name, several names, or `"all"`.

## 6. Reading data with `m3read()`

### 6.1 Excel

```r
raw <- m3read(
  file = "G:/project/coding-file.xlsx",
  sheet = 1
)
```

`sheet` can be an index or worksheet name.

### 6.2 CSV, TSV, and text files

```r
raw <- m3read(
  file = "G:/project/coding-file.csv",
  encoding = "auto"
)
```

`encoding = "auto"` tries UTF-8, GB18030, and GBK, and detects comma,
semicolon, or tab separators. For a decimal-comma file:

```r
raw <- m3read("data.csv", decimal = ",")
```

### 6.3 Required checks after import

```r
dim(raw)
names(raw)
head(raw)
str(raw)
attr(raw, "meta3_source")$name_map
```

`m3read()` may preserve text-form numeric columns to avoid silently changing
source coding. Package preparation and moderator functions parse values using
the recorded decimal setting. For arithmetic outside the package, inspect and
convert explicitly.

Duplicate headers are repaired according to source position. Always use the
repaired names shown by `names(raw)`.

## 7. Preparing effect sizes with `m3prep()`

### 7.1 Correlations

```r
dat <- m3prep(
  raw,
  measure = "r",
  study = "studyID",
  effect = "effectID",
  value = "r",
  n = "n"
)
```

The analysis uses `yi = atanh(r)` and `vi = 1/(n - 3)`. Overall effects,
category effects, predictions, and sensitivity estimates are automatically
transformed back to r for reporting.

### 7.2 Independent-groups Cohen's d

```r
raw$control_n <- raw$total_n - raw$intervention_n

dat <- m3prep(
  raw,
  measure = "d",
  design = "independent",
  study = "studyID",
  effect = "effectID",
  value = "cohens_d",
  n1 = "intervention_n",
  n2 = "control_n"
)
```

The exact Hedges correction converts d to g. Both the model and report use g.
Maintain a consistent group order and effect direction across studies.

### 7.3 Precomputed Hedges' g

```r
dat <- m3prep(
  raw,
  measure = "g",
  study = "studyID",
  effect = "effectID",
  value = "hedges_g",
  vi = "g_variance"
)
```

If only a standard error is available, square it first:

```r
raw$g_variance <- raw$g_se^2
```

### 7.4 One-group or pre-post d/g

Prefer a design-specific sampling variance:

```r
dat <- m3prep(
  raw,
  measure = "d",
  design = "onegroup",
  variance = "known",
  study = "studyID",
  effect = "effectID",
  value = "within_d",
  n = "intervention_n",
  vi = "within_d_variance"
)
```

If the design-specific variance truly cannot be recovered, use the approximate
option only as a clearly disclosed sensitivity model:

```r
dat <- m3prep(
  raw,
  measure = "d",
  design = "onegroup",
  variance = "approximate",
  study = "studyID",
  effect = "effectID",
  value = "within_d",
  n = "intervention_n"
)
```

Pre-post sampling variance often depends on the pre-post correlation and
standardization definition. Do not present an approximation as the only exact
analysis.

### 7.5 OR with a 95% confidence interval

```r
dat <- m3prep(
  raw,
  measure = "or",
  study = "studyID",
  effect = "effectID",
  value = "OR",
  lower = "OR_lower",
  upper = "OR_upper",
  conf = 0.95
)
```

### 7.6 OR with log(OR) SE or variance

```r
dat <- m3prep(
  raw, measure = "or",
  study = "studyID", effect = "effectID",
  value = "OR", se = "logOR_se"
)

dat <- m3prep(
  raw, measure = "or",
  study = "studyID", effect = "effectID",
  value = "OR", vi = "logOR_variance"
)
```

Both `se` and `vi` refer to log(OR), not raw OR.

### 7.7 OR from a 2 x 2 table

```r
dat <- m3prep(
  raw,
  measure = "or",
  study = "studyID",
  effect = "effectID",
  cellA = "intervention_event",
  cellB = "intervention_nonevent",
  cellC = "control_event",
  cellD = "control_nonevent",
  correction = 0.5
)
```

By default, 0.5 is added to all four cells only when a table contains a zero.
Keep event definitions and group directions consistent.

### 7.8 Custom `yi/vi`

```r
dat <- m3prep(
  raw,
  measure = "custom",
  study = "studyID",
  effect = "effectID",
  value = "yi",
  vi = "vi"
)
```

The publication must report the transformation formula, direction, assumptions,
and the formula used to obtain `vi`.

### 7.9 No effect ID column

Omit `effect`; stable IDs are generated from original row numbers.

```r
dat <- m3prep(
  raw, measure = "r",
  study = "studyID", value = "r", n = "n"
)
```

## 8. Three-level main effect

```r
main <- m3fit(
  dat,
  method = "REML",
  f = TRUE,
  level = "three"
)

summary(main)
m3effect(main)
m3i2(main)
m3lrt(main)
```

The core model is equivalent to:

```r
metafor::rma.mv(
  yi,
  V = vi,
  random = ~ 1 | studyID/effectID,
  method = "REML",
  test = "t",
  data = dat
)
```

Internally, `tdist = TRUE` may be used for compatibility. Coefficients then use
t tests and moderator omnibus tests use an F reference distribution. The
object may still store the statistic in `$QM`; it can be reported as F only
when the model actually used t/F inference.

### 8.1 Reporting scale

```r
overall <- m3effect(main)
overall
```

- `estimate_analysis`: Fisher z, g, log(OR), or custom analysis scale.
- `estimate_reported`: automatically reported as r, g, OR, or custom scale.
- `ci_lb_reported`, `ci_ub_reported`: confidence interval on reporting scale.

### 8.2 Multilevel I-squared

```r
i2 <- m3i2(main)
i2
```

The three rows usually represent between-study Level 3, within-study Level 2,
and total I-squared. I-squared describes the proportion of total variation
attributable to heterogeneity. A near-zero variance is a boundary estimate, not
proof that the population variance is exactly zero.

### 8.3 One-sided variance-component LRT

```r
lrt <- m3lrt(main)
lrt
```

`p_one_sided` uses a boundary-mixture reference approximation. Report Level 3
and Level 2 separately. This test does not replace an effect significance test.

## 9. Conventional random-effects meta-analysis

When each study has one effect, or the analysis should pool effects within
study first:

```r
single <- m3run(
  dat,
  level = "single",
  rho = 0.60,
  bias = TRUE,
  leave = TRUE,
  show = TRUE
)
```

The package uses GLS within-study pooling and then fits:

```r
metafor::rma(
  yi, vi,
  method = "REML",
  test = "knha"
)
```

### 9.1 Meaning of `rho`

`rho` is an assumed sampling correlation among effects within a study. It
cannot be estimated automatically from the effect-size table. Repeat plausible
values as a sensitivity analysis:

```r
rho_values <- c(0, 0.30, 0.60, 0.90)

rho_results <- lapply(rho_values, function(rho) {
  x <- m3run(
    dat,
    level = "single",
    rho = rho,
    bias = FALSE,
    leave = FALSE,
    show = FALSE
  )
  data.frame(rho = rho, x$main$overall)
})

do.call(rbind, rho_results)
```

### 9.2 Pooling only

```r
study_dat <- m3study(
  dat,
  rho = 0.60,
  keep = c("age", "design")
)
```

Only study-level variables can be preserved. The function stops when values
conflict within a study rather than averaging them silently.

## 10. Continuous moderators with `m3cont()`

```r
age <- m3cont(
  dat,
  var = "age",
  name = "Mean age",
  level = "three"
)

print(age)
age$center
age$coefficients
age$f_test
age$i2
age$lrt
```

The complete-case mean is used to create
`moderator_c = original value - mean`. Only an intercept model is fitted.

- Intercept: pooled effect at the complete-case moderator mean.
- `moderator_c`: change in the analysis-scale effect per original-unit increase.
- `$f_test`: F, numerator df, denominator df, and p for the moderator.

For correlations, the slope is on Fisher's-z scale. Do not apply `tanh()` to
the slope and call it the change in r per unit. For OR, the slope is on
log(OR) scale. Interpret predictions at meaningful moderator values.

## 11. Categorical moderators with `m3group()`

```r
design <- m3group(
  dat,
  var = "design",
  ref = "cross-sectional",
  name = "Study design"
)

print(design)
design$reference
design$counts_effects
design$counts_studies
design$contrasts
design$group_effects
design$f_test
```

The package fits:

- an intercept model, where the intercept is the reference-group effect and
  other coefficients are differences from it; and
- a no-intercept model, where each coefficient is a category-specific pooled
  effect transformed to the reporting scale.

The reference must be an observed category. Categories represented by only one
study usually produce unstable estimates and F tests.

## 12. Natural-spline analysis with `m3spline()`

```r
age_curve <- m3spline(
  dat,
  var = "age",
  df = 1:3,
  linear = TRUE,
  name = "Age"
)

print(age_curve)
age_curve$comparison
age_curve$minimum_ic_model
age_curve$best_model
age_curve$selection_criterion
```

Candidates use identical complete cases and ML, rather than REML, to compare
log likelihood, AIC, AICc, BIC, and delta.

- `minimum_ic_model`: candidate with the lowest chosen information criterion.
- `best_model`: simpler candidate preferred among models with delta <= 2.
- `selection_criterion`: AICc or AIC, according to the current comparison.

Do not increase df without an a priori reason. High-df curves can be unstable
when studies are few or moderator boundaries are sparsely observed.

## 13. Running multiple analyses with `m3run()`

```r
result <- m3run(
  dat,
  cont = list(
    list(var = "age", name = "Mean age"),
    list(var = "year", name = "Publication year")
  ),
  groups = list(
    list(
      var = "design",
      ref = "cross-sectional",
      name = "Study design"
    )
  ),
  spline = list(
    list(
      var = "age",
      df = 1:3,
      linear = TRUE,
      name = "Age curve"
    )
  ),
  bias = TRUE,
  leave = TRUE,
  rho = 0.60,
  level = "three",
  show = TRUE,
  keep = TRUE,
  code = FALSE
)
```

Names must be unique within each component type. Continuous variables can be
abbreviated as:

```r
cont = c("age", "year")
```

## 14. Publication-bias and small-study-effect diagnostics

```r
bias <- m3bias(
  dat,
  rho = 0.60,
  extra = TRUE,
  direction = "auto",
  level = "three"
)

print(bias)
```

### 14.1 Core output

```r
bias$pet_coefficients
bias$pet_f
bias$peese_coefficients
bias$peese_f
bias$decision
bias$selected_effect
```

Three-level PET/PEESE retains the dependent-effect structure. The default
decision uses PEESE when the PET intercept has p < .05 and PET otherwise. This
rule does not replace substantive judgment.

### 14.2 Supplementary study-level methods

With `extra = TRUE`, effects are first pooled to one effect per study using
`rho`, then the package attempts:

```r
bias$single_egger
bias$trimfill
bias$begg
bias$fail_safe_n
bias$three_psm
bias$vevea_table
bias$copas
bias$puniform
bias$pcurve
bias$zcurve_note
bias$study_reported_effects
```

Some methods require optional packages or enough significant studies. When
requirements are not met, the component is skipped or returns a readable
error.

### 14.3 Correct interpretation

- Significant Egger means an association between effect and precision: a
  small-study effect or funnel asymmetry, not proven publication bias.
- Significant Egger and zero trim-and-fill imputations can coexist because the
  methods detect different patterns.
- Hedges' g can be mechanically related to its SE or variance, so interpret
  PET-PEESE cautiously.
- Selection models and p-uniform-type methods are supplementary sensitivity
  evidence, not votes that mechanically determine a conclusion.

## 15. Leave-one-out sensitivity analysis

```r
loo_effect <- m3leave(dat, by = "effect")
loo_study <- m3leave(dat, by = "study")

loo_effect$full_effect
loo_effect$results
loo_study$full_effect
loo_study$results
```

The table contains the omitted ID, number of effects removed, effects and
studies remaining, pooled effect, p value, confidence interval, and fitting
error.

- Leave-one-effect-out removes one effect row at a time.
- Leave-one-study-out removes all effects from one study and is the stronger
  cluster-level sensitivity analysis.

Report the range of pooled effects, direction changes, significance changes,
and whether one study drives the result.

## 16. Plotting with `m3plot()`

### 16.1 Plot from a complete workflow

```r
m3plot(result, "forest")
m3plot(result, "cont", name = "Mean age")
m3plot(result, "spline", name = "Age curve")
m3plot(result, "bias")
m3plot(result, "effect")
m3plot(result, "study")
```

Continuous and spline results can be selected by display name, original
variable name, or `index`.

### 16.2 Linear moderator plot

```r
pred_age <- m3plot(
  result,
  "cont",
  name = "Mean age",
  point_col = "gray70",
  line_col = "black",
  ci_col = "gray45",
  main = "Age moderator",
  xlab = "Age"
)
```

The invisible prediction table contains `x`, `estimate`, `ci_lb`, and `ci_ub`.

### 16.3 Spline plot

```r
result$spline[["Age curve"]]$comparison

pred_curve <- m3plot(
  result,
  "spline",
  name = "Age curve",
  models = c("linear", "spline_df3"),
  colors = c("gray35", "black"),
  line_types = c(2, 1),
  show_ci = "spline_df3",
  main = "Age moderator: linear vs spline df=3"
)
```

Model names must come from `$models` or `$comparison$model`.

### 16.4 Save high-resolution figures

```r
png(
  "age-moderator.png",
  width = 2400,
  height = 1800,
  res = 300,
  type = "cairo"
)
m3plot(result, "cont", name = "Mean age")
dev.off()
```

For a PDF:

```r
grDevices::cairo_pdf("study-sensitivity.pdf", width = 8, height = 6)
m3plot(result, "study")
grDevices::dev.off()
```

## 17. Extracting result objects

The complete workflow contains:

```r
names(result)
# main cont groups spline bias effectleave studyleave
```

### 17.1 Main result

```r
result$main$model
result$main$overall
result$main$i2
result$main$lrt
result$main$aggregation
result$main$prediction
```

### 17.2 Continuous moderator

```r
result$cont[["Mean age"]]$center
result$cont[["Mean age"]]$coefficients
result$cont[["Mean age"]]$f_test
result$cont[["Mean age"]]$i2
result$cont[["Mean age"]]$lrt
```

### 17.3 Categorical moderator

```r
result$groups[["Study design"]]$reference
result$groups[["Study design"]]$counts_effects
result$groups[["Study design"]]$counts_studies
result$groups[["Study design"]]$contrasts
result$groups[["Study design"]]$group_effects
result$groups[["Study design"]]$f_test
```

### 17.4 Spline

```r
result$spline[["Age curve"]]$comparison
result$spline[["Age curve"]]$minimum_ic_model
result$spline[["Age curve"]]$best_model
```

### 17.5 Bias and sensitivity

```r
result$bias$selected_effect
result$bias$study_reported_effects
result$effectleave$results
result$studyleave$results
```

## 18. Exporting tables

The package does not force automatic file saving. Export the required result
objects explicitly.

### 18.1 CSV

```r
write.csv(
  result$studyleave$results,
  "leave-one-study-out.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
```

### 18.2 Excel

```r
install.packages("openxlsx")
library(openxlsx)

write.xlsx(
  list(
    main = result$main$overall,
    i2 = result$main$i2,
    lrt = result$main$lrt,
    leave_effect = result$effectleave$results,
    leave_study = result$studyleave$results
  ),
  file = "meta-analysis-results.xlsx",
  overwrite = TRUE
)
```

## 19. Console reporting, audit code, and source inspection

```r
m3report(result)
m3report(result, code = TRUE)
m3code(result)
m3code(result, file = "analysis-audit.R")
m3source("m3bias")
m3source("all", print = FALSE, file = "meta3level-source.R")
sessionInfo()
```

Saving `m3code()` also creates a matching `_data.rds` file. Keep both files
together. The snapshot contains the IDs, `yi`, `vi`, and moderators needed by
the fitted analysis, but it remains research data and must be checked before
public sharing.

## 20. Reporting results in a paper

### 20.1 Main effect

Report the effect type and transformation, model, REML, number of effects,
number of independent studies, pooled effect and 95% CI, p value, Level 3 and
Level 2 variances, multilevel I-squared, QE, and one-sided LRTs.

Suggested structure:

> A three-level random-effects model estimated with REML nested effect sizes
> within studies. Correlations were transformed to Fisher's z for analysis and
> back-transformed to r for reporting. The analysis included k = ... effects
> from ... independent studies. The pooled effect was r = ..., 95% CI [...],
> p = .... Level 3 and Level 2 variances were ... and ..., corresponding to
> I-squared values of ...% and ...%.

### 20.2 Continuous moderator

Report the centering mean, slope, SE, t, denominator df, p, CI, and omnibus F.

> Age was centered at the complete-case mean of ... years. The moderator slope
> was b = ..., SE = ..., t(df) = ..., p = ..., 95% CI [...]; omnibus
> F(1, df) = ..., p = ....

### 20.3 Categorical moderator

Report the reference category, effect/study counts in every category, omnibus
F, reference-group contrasts, and reporting-scale pooled category effects from
the no-intercept model.

### 20.4 Spline

Report the common analysis sample, ML estimation, candidate set, AIC/AICc/BIC,
delta, and parsimony rule. Explain why a more complex candidate was or was not
selected when fit differences are small.

### 20.5 Publication-bias diagnostics

Use wording such as "funnel asymmetry" or "small-study effects" rather than
claiming publication bias has been proven. Identify which models retain the
dependent-effect structure and which use one pooled effect per study.

### 20.6 Leave-one-out

Report the range of pooled effects after deletion, any direction or
significance changes, the most influential study, and the number of effects
removed for every leave-one-study-out iteration.

## 21. Troubleshooting

### 21.1 A CSV imports as only one or three columns

Check separator, encoding, and decimal mark.

```r
raw <- m3read("data.csv", encoding = "auto")
dim(raw)
names(raw)
```

### 21.2 A required column is missing or duplicated

```r
names(raw)
attr(raw, "meta3_source")$name_map
```

Use actual imported names rather than visually guessing duplicate headers.

### 21.3 A three-level model reports no repeated effects

Use `level = "single"`. Never duplicate effect rows merely to make a
three-level model run.

### 21.4 An F statistic is stored as QM

This is historical `metafor` object naming. Verify `test = "t"` or
`tdist = TRUE`; only then is the omnibus statistic interpreted with an F
reference distribution.

### 21.5 F is nonsignificant while z/QM is significant

Small-sample t/F inference uses finite denominator degrees of freedom and is
usually more conservative. Report the prespecified F result rather than
choosing the smaller p value after analysis.

### 21.6 A variance component equals zero

This is an allowed boundary estimate. Inspect the number of studies, number of
studies with repeated effects, LRT, and model warnings. Do not modify the value.

### 21.7 Egger is significant but trim-and-fill imputes zero studies

The methods target different asymmetry patterns and can legitimately disagree.
Report and explain the discrepancy rather than automatically treating it as a
coding error.

### 21.8 Spline prediction cannot match variables 2 or 3

Do not pass a bare numeric vector to `predict()` for a spline model. Use
`m3plot()` or reconstruct the natural-spline basis using the original knots and
boundary knots.

### 21.9 Optional analysis fails but the workflow continues

```r
inherits(result$bias, "meta3_error")
result$bias$message
```

Set `m3run(..., keep = FALSE)` to stop at the first optional-component error.

## 22. Multiple testing and analysis standards

- Prespecify continuous, categorical, and spline moderators where possible.
- Do not rearrange categories or increase spline df to search for significance.
- Label exploratory analyses and consider multiplicity.
- Variance, F, and publication-bias tests are often unstable with fewer than
  ten independent studies.
- The default three-level model uses diagonal `V = vi`. When shared
  participants, shared controls, or algebraic relationships create known
  sampling covariances, construct a design-specific V matrix; random effects do
  not replace known sampling covariance.
- Effects representing different constructs, comparisons, or time points may
  not be suitable for pooling into one study effect in a conventional model.

## 23. Complete replaceable template

```r
library(meta3level)

# 1. Read ---------------------------------------------------------------
raw <- m3read(
  file = "REPLACE_WITH_FULL_PATH/coding-file.xlsx",
  sheet = 1
)

names(raw)
head(raw)

# 2. Prepare: correlation example --------------------------------------
dat <- m3prep(
  raw,
  measure = "r",
  study = "REPLACE_STUDY_ID_COLUMN",
  effect = "REPLACE_EFFECT_ID_COLUMN",
  value = "REPLACE_R_COLUMN",
  n = "REPLACE_SAMPLE_SIZE_COLUMN"
)

# 3. Complete workflow --------------------------------------------------
result <- m3run(
  dat,
  cont = c(
    "REPLACE_CONTINUOUS_MODERATOR_1",
    "REPLACE_CONTINUOUS_MODERATOR_2"
  ),
  groups = list(
    list(
      var = "REPLACE_CATEGORICAL_MODERATOR",
      ref = "REPLACE_OBSERVED_REFERENCE_VALUE",
      name = "REPLACE_DISPLAY_NAME"
    )
  ),
  spline = list(
    list(
      var = "REPLACE_NONLINEAR_MODERATOR",
      df = 1:3,
      linear = TRUE,
      name = "REPLACE_SPLINE_DISPLAY_NAME"
    )
  ),
  bias = TRUE,
  leave = TRUE,
  rho = 0.60,
  level = "three",  # use "single" for conventional meta-analysis
  show = TRUE,
  keep = TRUE,
  code = FALSE
)

# 4. Extract ------------------------------------------------------------
result$main$overall
result$main$i2
result$main$lrt
result$cont[[1]]$coefficients
result$cont[[1]]$f_test
result$groups[[1]]$counts_effects
result$groups[[1]]$counts_studies
result$groups[[1]]$group_effects
result$groups[[1]]$f_test
result$spline[[1]]$comparison
result$bias$selected_effect
result$effectleave$results
result$studyleave$results

# 5. Plot ---------------------------------------------------------------
m3plot(result, "forest")
m3plot(result, "cont", 1)
m3plot(result, "spline", 1)
m3plot(result, "bias")
m3plot(result, "effect")
m3plot(result, "study")

# 6. Audit --------------------------------------------------------------
m3report(result, code = TRUE)
m3code(result, file = "analysis-audit.R")
m3source("all", print = FALSE, file = "meta3level-source.R")
sessionInfo()
```

## 24. Getting help and reporting a bug

Before reporting a problem, run:

```r
packageVersion("meta3level")
sessionInfo()
```

Include the complete error, a minimal reproducible and de-identified example,
the exact function call, effect-size definition, and expected behavior. Do not
publish participant names, unredacted coding sheets, or restricted research
data.

For a compact function-only guide, see `FUNCTION_REFERENCE.en.md` in the
repository.
