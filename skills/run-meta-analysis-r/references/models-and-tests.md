# Models and Tests

## Contents

- Three-level main model
- F inference
- Heterogeneity and LRT
- Continuous moderators
- Categorical moderators
- Spline comparison
- Conventional meta-analysis

## Three-Level Main Model

Use:

```r
model <- metafor::rma.mv(
  yi, V = vi,
  random = ~ 1 | studyID/effectID,
  method = "REML",
  test = "t",
  data = dat
)
```

Print `summary(model)`, retained k, unique studies, variance components, residual
QE, pooled effect on both analysis and reporting scales, and a prediction
interval when scientifically useful and supported by the model.

## F Inference

With `rma.mv(test = "t")`, individual coefficients use t tests and the omnibus
moderator test uses F. `metafor` retains the historical field name `QM` for the
numeric omnibus statistic. Extract:

```r
data.frame(
  F = as.numeric(model$QM),
  df1 = as.numeric(model$QMdf[1]),
  df2 = as.numeric(model$QMdf[2]),
  p = as.numeric(model$QMp)
)
```

Verify `model$test` before labeling. A z-based model's QM is chi-square, not F.

## Heterogeneity and LRT

Compute a typical sampling variance and divide total variability into Level 3,
Level 2, and sampling variance. State the exact formula used. For variance-
component boundary tests, refit a model with one component fixed to zero and use:

```r
lrt <- max(0, 2 * (logLik(full) - logLik(reduced)))
pOneSided <- 0.5 * pchisq(lrt, df = 1, lower.tail = FALSE)
```

Compare models with identical fixed effects and estimation method. Report
boundary estimates and failed reduced fits instead of replacing them.

## Continuous Moderators

Use moderator-specific complete cases, then center:

```r
center <- mean(datMod$moderatorRaw)
datMod$moderatorC <- datMod$moderatorRaw - center
```

Fit `mods = ~ moderatorC`, print the complete model and F table, and report the
center. Do not fit a no-intercept continuous model. For plots, predict over the
observed range and show uncertainty and data density.

## Categorical Moderators

Clean labels, construct a factor, and explicitly relevel it. Fit:

```r
withIntercept <- rma.mv(..., mods = ~ moderatorFactor, test = "t")
noIntercept <- rma.mv(..., mods = ~ 0 + moderatorFactor, test = "t")
```

Use the intercept model for contrasts and omnibus F. Use the no-intercept model
for each category's pooled effect and back-transform those coefficients when
appropriate. Print effects and independent studies per category. Warn when a
category has fewer than two studies or categories approach the study count.

## Spline Comparison

Select complete cases once, center once, and use ML for all candidates. Construct
natural-spline matrices with explicit names such as `spline1`, `spline2`, and
`spline3`. Store and reuse the basis knots and boundary knots for prediction.

Calculate AICc from ML log likelihood:

```r
ll <- logLik(model)
p <- attr(ll, "df")
k <- model$k
aic <- AIC(model)
aicc <- if (k > p + 1) aic + 2 * p * (p + 1) / (k - p - 1) else NA_real_
```

Compare identical k and study counts. Among models with delta AICc <= 2, prefer
the least complex candidate unless substantive theory supports another model.
Do not increase df repeatedly only because a higher-df model lowers AIC in one
small dataset.

## Conventional Meta-Analysis

Require one independent estimate per study. If dependent effects must be pooled,
use a stated covariance model under rho and generalized least squares. Then fit:

```r
model <- metafor::rma(
  yi, vi,
  method = "REML",
  test = "knha",
  data = studyDat
)
```

Report original effects, pooled study effects, within-study counts, rho, pooled
effect, Q, tau-squared, I-squared, H-squared, and prediction interval. Repeat rho
sensitivity analyses when rho is assumed.

