# meta3level Public Function Quick Reference

This reference covers every function exported by `meta3level` 0.6.2. The package
exports 18 short `m3*` functions. Use `?function_name` for the formal R help page
and `m3source("function_name")` to inspect the installed implementation.

## 1. Typical order of use

1. `m3read()` reads the coding file.
2. `m3prep()` converts the reported effect size to analysis columns `yi` and
   `vi`.
3. Use `m3run()` for the complete workflow, or combine `m3fit()` with the
   specialist functions below.
4. `m3report()`, `m3plot()`, and `m3code()` print, visualize, and audit the
   result.

## 2. One-line overview

| Function | Simple purpose |
|---|---|
| `m3read()` | Read CSV, TSV, TXT, XLSX, or XLS coding files. |
| `m3prep()` | Prepare `r`, `d`, `g`, `OR`, or custom `yi/vi` for analysis. |
| `m3fit()` | Fit a three-level or conventional random-effects model. |
| `m3effect()` | Extract the intercept/overall effect on analysis and reporting scales. |
| `m3ftest()` | Extract the moderator omnibus F test. |
| `m3i2()` | Calculate multilevel or conventional heterogeneity statistics. |
| `m3lrt()` | Run one-sided boundary likelihood-ratio tests for variance components. |
| `m3cont()` | Analyze one centered continuous moderator. |
| `m3group()` | Analyze one categorical moderator with reference and group-mean models. |
| `m3spline()` | Compare linear and natural-spline moderator models using ML. |
| `m3study()` | Pool multiple dependent effects into one effect per study. |
| `m3bias()` | Run Egger/PET-PEESE and supplementary small-study-effect diagnostics. |
| `m3leave()` | Run leave-one-effect-out or leave-one-study-out analysis. |
| `m3run()` | Run the complete workflow with one call. |
| `m3plot()` | Draw the appropriate forest, moderator, spline, funnel, or sensitivity plot. |
| `m3report()` | Print a complete result again, optionally with audit code. |
| `m3code()` | Generate executable underlying-package R code for auditing. |
| `m3source()` | Display or save the actual installed package function definitions. |

## 3. Function-by-function guide

### `m3read()` - read a coding file

**Call:** `m3read(file, sheet = 1, encoding = "auto", decimal = ".", ...)`

**Use it when:** your data are stored in CSV, TSV, TXT, XLSX, or XLS format.

```r
raw <- m3read("coding-file.xlsx", sheet = 1)
```

**Main arguments:** `file`, `sheet`, `encoding`, and `decimal`. With
`encoding = "auto"`, common UTF-8 and Chinese encodings are tried. Delimited-
file separators are detected automatically.

**Returns:** a data frame with source information in
`attr(raw, "meta3_source")`. Inspect `names(raw)` and the stored `name_map`
after import, especially when the original file contains duplicate headers.

### `m3prep()` - prepare effect sizes

**Call:** `m3prep(data, measure, study, effect = NULL, value = NULL, n = NULL,
n1 = NULL, n2 = NULL, vi = NULL, se = NULL, lower = NULL, upper = NULL,
cellA = NULL, cellB = NULL, cellC = NULL, cellD = NULL, conf = 0.95,
correction = 0.5, design = "independent", variance = "known",
decimal = NULL)`

**Use it when:** raw reported statistics must be converted to model-ready
`yi` and `vi`.

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

**Main arguments:**

- `measure`: `"r"`, `"d"`, `"g"`, `"or"`, or `"custom"`.
- `study`, `effect`: study and effect identifiers. `effect` may be omitted;
  stable IDs are then generated from original row numbers.
- `value`: reported effect-size column.
- `n`, `n1`, `n2`: sample-size inputs.
- `vi`, `se`, `lower`, `upper`: uncertainty inputs.
- `cellA` to `cellD`: a 2 x 2 table for OR calculation.
- `design`: `"independent"` or `"onegroup"` for d/g inputs.

**Returns:** prepared data containing standardized `studyID`, `effectID`,
`yi`, `vi`, and the variables retained from the source. Correlations are
analyzed as Fisher's z, Cohen's d is corrected to Hedges' g, and OR is analyzed
as log(OR).

**Important:** `vi` means variance, not standard error. For custom effects,
the researcher must document the formula used to obtain both `yi` and `vi`.

### `m3fit()` - fit the main or custom model

**Call:** `m3fit(data, mods = NULL, method = "REML", f = TRUE,
sigma2 = c(NA, NA), warn = TRUE, level = "three", rho = 0.60, ...)`

**Use it when:** you need a main model or a manually specified moderator model.

```r
model <- m3fit(dat, level = "three", method = "REML", f = TRUE)
age_model <- m3fit(dat, mods = ~ age, level = "three", f = TRUE)
```

**Main arguments:** `mods`, `method`, `f`, `sigma2`, `level`, and `rho`.
`level = "three"` fits study/effect nesting. `level = "single"` first pools
dependent effects by study using `rho`, then fits a conventional model.

**Returns:** a fitted `metafor` model. With `f = TRUE`, coefficients use t
inference and moderator omnibus tests use an F reference distribution. The
statistic may still be stored in the historical `$QM` field inside `metafor`.

### `m3effect()` - extract the overall effect

**Call:** `m3effect(model, back = TRUE)`

```r
overall <- m3effect(model)
```

**Use it when:** you want a compact table containing the estimate, uncertainty,
p value, and confidence interval. For `r` and `OR`, values are automatically
reported as correlations and odds ratios when `back = TRUE`.

**Important:** if the model contains moderators, the first coefficient is the
intercept, not an unconditional effect across all moderator values.

### `m3ftest()` - extract the moderator F test

**Call:** `m3ftest(model)`

```r
f_result <- m3ftest(age_model)
```

**Use it when:** a fitted moderator model used t/F inference and you need the
omnibus F statistic, numerator df, denominator df, and p value in a clean table.

### `m3i2()` - report heterogeneity

**Call:** `m3i2(model)`

```r
heterogeneity <- m3i2(model)
```

**Returns:** Level 3, Level 2, and total I-squared for a three-level model, or
conventional heterogeneity results for a single-level model. A variance estimate
of zero is an allowed boundary estimate and must not be manually changed.

### `m3lrt()` - test variance components

**Call:** `m3lrt(model, data = model$meta3_data)`

```r
variance_tests <- m3lrt(model)
```

**Use it when:** you need one-sided boundary likelihood-ratio tests for Level 3
and Level 2 variances. These tests concern heterogeneity components, not the
significance of the pooled effect.

### `m3cont()` - analyze a continuous moderator

**Call:** `m3cont(data, var, name = var, method = "REML", level = "three",
rho = 0.60)`

```r
age_result <- m3cont(dat, var = "age", name = "Mean age")
```

**What it does:** keeps complete cases for that moderator, centers the variable
at their mean, fits an intercept model, and prints coefficients, the F test,
heterogeneity, and LRT results.

**Key outputs:** `$center`, `$coefficients`, `$f_test`, `$i2`, and `$lrt`.
Continuous moderators do not receive a no-intercept model. A correlation-model
slope is on the Fisher-z scale and an OR-model slope is on the log(OR) scale.

### `m3group()` - analyze a categorical moderator

**Call:** `m3group(data, var, ref, name = var, method = "REML",
level = "three", rho = 0.60)`

```r
design_result <- m3group(
  dat,
  var = "design",
  ref = "cross-sectional",
  name = "Study design"
)
```

**What it does:** fits an intercept model in which `ref` is the reference group
and a no-intercept model that estimates the pooled effect for every category.

**Key outputs:** `$reference`, `$counts_effects`, `$counts_studies`,
`$contrasts`, `$group_effects`, and `$f_test`. The reference value must exactly
match a cleaned category in the data.

### `m3spline()` - compare nonlinear moderator models

**Call:** `m3spline(data, var, df = 1:3, linear = TRUE, name = var,
level = "three", rho = 0.60)`

```r
curve_result <- m3spline(
  dat,
  var = "age",
  df = 1:3,
  linear = TRUE,
  name = "Age"
)
```

**What it does:** fits all candidates to identical complete cases using ML and
compares log likelihood, AIC, AICc, BIC, and delta values.

**Key outputs:** `$comparison`, `$minimum_ic_model`, `$best_model`,
`$selection_criterion`, and `$models`. Do not keep increasing df merely to find
a significant curve; complex splines become unstable with few independent
studies or sparse boundary data.

### `m3study()` - pool effects within studies

**Call:** `m3study(data, rho = 0.60, keep = character())`

```r
one_per_study <- m3study(dat, rho = 0.60, keep = c("age", "design"))
```

**Use it when:** a conventional analysis requires one effect per study.
`rho` is an assumed sampling correlation and should be varied in sensitivity
analyses. `keep` may contain only variables that are constant within each study;
the function stops instead of silently averaging conflicting values.

### `m3bias()` - assess small-study effects

**Call:** `m3bias(data, rho = 0.60, extra = TRUE, direction = "auto",
level = "three")`

```r
bias_result <- m3bias(
  dat,
  rho = 0.60,
  extra = TRUE,
  direction = "auto",
  level = "three"
)
```

**Core outputs:** multilevel or conventional PET and PEESE coefficients/F
tests, the PET-PEESE decision, and the selected adjusted intercept.

**Supplementary outputs:** study-level Egger, trim-and-fill, Begg, fail-safe N,
selection models, Copas, p-uniform, p-curve, and related diagnostics when their
optional packages and data requirements are available.

**Important:** funnel asymmetry or a significant Egger regression indicates a
small-study effect, not definitive proof of publication bias. Supplementary
methods may legitimately disagree.

### `m3leave()` - run leave-one-out sensitivity analysis

**Call:** `m3leave(data, by = "effect", method = "REML", level = "three",
rho = 0.60)`

```r
effect_loo <- m3leave(dat, by = "effect")
study_loo <- m3leave(dat, by = "study")
```

**Key outputs:** `$full_effect` and `$results`. The results include the omitted
ID, number of effects removed, effects and studies remaining, pooled estimate,
p value, confidence interval, and any fitting error.

### `m3run()` - run the complete workflow

**Call:** `m3run(data, cont = NULL, groups = NULL, spline = NULL,
bias = TRUE, leave = TRUE, rho = 0.60, level = "three", show = TRUE,
keep = TRUE, code = FALSE)`

```r
result <- m3run(
  dat,
  cont = c("age", "year"),
  groups = list(
    list(var = "design", ref = "cross-sectional", name = "Study design")
  ),
  spline = list(
    list(var = "age", df = 1:3, name = "Age curve")
  ),
  bias = TRUE,
  leave = TRUE,
  level = "three",
  show = TRUE,
  keep = TRUE
)
```

**Use it when:** you want the main analysis and selected optional analyses in a
single structured object. `show = TRUE` prints the complete console report.
With `keep = TRUE`, an optional component may fail without stopping the other
components; a main-model failure always stops the workflow.

**Top-level outputs:** `$main`, `$cont`, `$groups`, `$spline`, `$bias`,
`$effectleave`, and `$studyleave`.

### `m3plot()` - draw a result

**Call:** `m3plot(x, what = NULL, index = 1, name = NULL, ...)`

```r
m3plot(result, "forest")
m3plot(result, "cont", name = "age")
m3plot(result, "spline", name = "Age curve")
m3plot(result, "bias")
m3plot(result, "effect")
m3plot(result, "study")
```

**Use it when:** you need the appropriate forest, linear-moderator, spline,
funnel, or leave-one-out plot. For workflows containing several moderators,
select one with `name` or `index`. Additional graphical options are passed
through `...`.

### `m3report()` - print a result again

**Call:** `m3report(x, code = FALSE, ...)`

```r
m3report(result)
m3report(result, code = TRUE)
```

**Use it when:** an existing result should be reprinted in the console. With
`code = TRUE`, the underlying-package audit code follows the report.

### `m3code()` - generate auditable R code

**Call:** `m3code(x, print = TRUE, file = NULL)`

```r
m3code(result)
m3code(result, file = "analysis-audit.R")
```

**Returns:** executable code that calls underlying packages directly rather
than relying on `meta3level` analysis wrappers. When a file is requested, a
matching `_data.rds` snapshot is also written; keep the script and snapshot
together and check the snapshot before sharing it.

### `m3source()` - inspect the installed implementation

**Call:** `m3source(fun = "all", print = TRUE, file = NULL)`

```r
m3source("m3bias")
m3source("all", print = FALSE, file = "meta3level-source.R")
```

**Use it when:** reviewers or researchers need the exact installed function
definitions. `fun` can be one name, a vector of names, or `"all"`.

## 4. Help and audit commands

```r
help(package = "meta3level")
?m3prep
args(m3prep)
m3source("m3prep")
packageVersion("meta3level")
sessionInfo()
```

When reporting a problem, include the package version, complete error message,
function call, effect-size definition, and a minimal de-identified example.
