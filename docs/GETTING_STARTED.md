# Getting Started

## 1. Install

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

For the optional Excel and publication-bias features:

```r
install.packages(c("readxl", "openxlsx", "meta", "metasens", "puniform"))
```

## 2. Verify the installation

```r
packageVersion("meta3level")
help(package = "meta3level")
```

Expected version: `0.6.2`.

## 3. Run the synthetic example

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
  show = TRUE,
  keep = FALSE,
  code = FALSE
)
```

The synthetic example has only eight studies, so small-sample warnings are
expected. It is intended to verify software behavior, not support substantive
inference.

## 4. Replace the example mapping

Only replace column names and design choices. Do not rename the source coding
file unless needed.

### Correlation

```r
dat <- m3prep(
  raw, measure = "r",
  study = "studyID", effect = "effectID",
  value = "r", n = "sampleSize"
)
```

### Independent-groups Cohen's d

```r
dat <- m3prep(
  raw, measure = "d", design = "independent",
  study = "studyID", effect = "effectID",
  value = "cohensD", n1 = "interventionN", n2 = "controlN"
)
```

### Precomputed Hedges' g

```r
dat <- m3prep(
  raw, measure = "g",
  study = "studyID", effect = "effectID",
  value = "hedgesG", vi = "varianceG"
)
```

### Odds ratio from a 2 by 2 table

```r
dat <- m3prep(
  raw, measure = "or",
  study = "studyID", effect = "effectID",
  cellA = "treatmentEvents", cellB = "treatmentNonEvents",
  cellC = "controlEvents", cellD = "controlNonEvents"
)
```

### Other effect sizes

```r
dat <- m3prep(
  raw, measure = "custom",
  study = "studyID", effect = "effectID",
  value = "yi", vi = "vi"
)
```

The researcher must document the transformation and sampling-variance formula
for custom effects.

## 5. Run selected components

```r
main <- m3fit(dat)
summary(main)
m3effect(main)
m3i2(main)
m3lrt(main)

age <- m3cont(dat, "age", name = "Age")
design <- m3group(dat, "design", ref = "cross-sectional")
curve <- m3spline(dat, "age", df = 1:3)
bias <- m3bias(dat, rho = 0.60)
effectLeave <- m3leave(dat, by = "effect")
studyLeave <- m3leave(dat, by = "study")
```

## 6. Create plots

```r
m3plot(result, "forest")
m3plot(result, "cont", name = "age")
m3plot(result, "spline", name = "age")
m3plot(result, "effect")
m3plot(result, "study")
```

## 7. Audit the analysis

```r
m3report(result, code = TRUE)
m3code(result, file = "analysis-audit.R")
m3source("all", print = FALSE, file = "meta3level-source.R")
sessionInfo()
```

Keep `analysis-audit.R` together with the generated `_data.rds` sidecar.
