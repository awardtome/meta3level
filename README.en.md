# meta3level

`meta3level` provides auditable three-level and conventional random-effects
meta-analysis workflows in R. Version `0.6.2` supports correlations, Cohen's d,
Hedges' g, odds ratios, and effect sizes supplied with known sampling variances.

[Chinese README](README.md) | [Getting started](docs/GETTING_STARTED.md) |
[Data requirements](docs/DATA_REQUIREMENTS.md) |
[Statistical workflow](docs/STATISTICAL_WORKFLOW.md) |
[Output and reporting](docs/OUTPUT_AND_REPORTING.md) |
[AI skill](docs/AI_SKILL.md) | [Complete English manual](USER_MANUAL.en.md) |
[Function reference](FUNCTION_REFERENCE.en.md)

Chinese resources: [complete user manual](USER_MANUAL.zh-CN.md),
[function reference](FUNCTION_REFERENCE.zh-CN.md), and
[repository file guide](FILES.zh-CN.md).

## Design goals

- Short, package-specific `m3*` function names minimize namespace conflicts.
- Correlations are analyzed on Fisher's z and reported as r.
- Cohen's d is corrected to Hedges' g before modeling.
- Odds ratios are analyzed on log(OR) and reported as OR where appropriate.
- Three-level models use study/effect nesting and `metafor` t/F inference.
- Continuous moderators are centered and use intercept models only.
- Categorical moderators provide reference-group contrasts and no-intercept
  pooled estimates for every category.
- Natural-spline candidates use identical complete cases and ML AIC/AICc/BIC.
- Results, plots, leave-one-out tables, and native underlying R code are
  available from the same analysis object.

## Installation

Install from GitHub:

```r
install.packages("remotes")
remotes::install_github(
  "awardtome/meta3level",
  dependencies = NA,
  upgrade = "never"
)
library(meta3level)
```

The core runtime requires `metafor`. Excel input and supplementary publication-
bias methods use optional packages listed under `Suggests` in `DESCRIPTION`.

## Minimal three-level analysis

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
    list(var = "design", ref = "cross-sectional", name = "Study design")
  ),
  spline = list(
    list(var = "age", df = 1:3, name = "Age")
  ),
  bias = FALSE,
  leave = TRUE,
  show = TRUE
)
```

Use `m3report(result, code = TRUE)` to print the report and native audit code.
Use `m3code(result, file = "analysis-audit.R")` to write an independent script
plus the minimal prepared-data snapshot needed for exact reproduction.

## Public API

| Function | Purpose |
|---|---|
| `m3read()` | Read CSV, TSV, XLSX, or XLS data |
| `m3prep()` | Prepare r, d, g, OR, or custom effects |
| `m3fit()` | Fit a three-level or conventional model |
| `m3effect()` | Extract the overall effect on the reporting scale |
| `m3ftest()` | Extract the `metafor` moderator F test |
| `m3i2()` | Report multilevel or conventional heterogeneity |
| `m3lrt()` | Run one-sided variance-component LRTs |
| `m3cont()` | Analyze a centered continuous moderator |
| `m3group()` | Analyze a categorical moderator |
| `m3spline()` | Compare linear and natural-spline models |
| `m3study()` | GLS-pool dependent effects within studies |
| `m3bias()` | Run small-study-effect and bias diagnostics |
| `m3leave()` | Run effect- or study-level leave-one-out analysis |
| `m3run()` | Run the complete workflow |
| `m3plot()` | Plot a compatible result |
| `m3report()` | Reprint complete console output |
| `m3code()` | Generate native underlying-package audit code |
| `m3source()` | Display the installed package source |

## Important boundaries

- A study ID must identify an independent sample, not merely a publication.
- A diagonal sampling-variance vector does not represent known sampling
  covariances caused by shared participants or shared controls.
- Single-group or pre-post standardized effects normally need a design-specific
  sampling variance, often involving the pre-post correlation.
- Egger tests diagnose funnel asymmetry or small-study effects; they do not prove
  publication bias.
- Sparse categories, few studies, and high-degree spline models require cautious
  interpretation even when estimation succeeds.

## Without installing the package

The repository also contains `skills/run-meta-analysis-r`, an Agent Skills
compatible workflow that instructs an AI coding agent to inspect a coding file
and generate direct, auditable `metafor` code. See [AI skill installation and
usage](docs/AI_SKILL.md).

## License

MIT. Copyright (c) 2026 awardtome.
