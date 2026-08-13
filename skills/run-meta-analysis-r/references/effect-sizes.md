# Effect-Size Decisions

## Contents

- Correlation r
- Independent-groups d and g
- Single-group or pre-post effects
- Odds ratios
- Custom effects
- Direction and validation

## Correlation r

Require r and total n. Analyze:

```r
yi <- atanh(r)
vi <- 1 / (n - 3)
```

Reject `|r| >= 1`, `n <= 3`, missing IDs, and nonfinite values. Back-transform
pooled estimates and intervals with `tanh()`. Keep moderator slopes in Fisher-z
units unless presenting model predictions at meaningful moderator values.

## Independent-Groups d and g

Require group sample sizes. For reported Cohen's d, use the exact Hedges
correction:

```r
df <- n1 + n2 - 2
J <- exp(lgamma(df / 2) - 0.5 * log(df / 2) - lgamma((df - 1) / 2))
g <- J * d
vi <- (n1 + n2) / (n1 * n2) + g^2 / (2 * (n1 + n2))
```

This matches `metafor::escalc(measure = "SMD", di = d, n1i = n1,
n2i = n2, vtype = "LS")` for the supported input design. If a design-specific
variance of d is supplied, transform it as `J^2 * vi_d` instead.

For precomputed g, prefer its reported/calculated sampling variance. If only g
and group sample sizes exist, use the stated SMD variance formula and disclose
that choice.

## Single-Group or Pre-Post Effects

Stop and obtain the exact effect definition and sampling-variance formula.
Pre-post standardized effects may use different denominators and commonly need
the pre-post correlation. Never apply the independent-groups formula. If the
researcher supplies valid g and vi, analyze them as precomputed effects. Treat an
approximate variance that omits the correlation as an explicitly labeled
sensitivity analysis, not an invisible default.

## Odds Ratios

Analyze `yi = log(OR)`. Require exactly one uncertainty route:

```r
# Known log(OR) variance
vi <- viLogOR

# Known log(OR) standard error
vi <- seLogOR^2

# OR and confidence interval
zcrit <- qnorm(1 - (1 - conf) / 2)
vi <- ((log(upper) - log(lower)) / (2 * zcrit))^2

# 2 by 2 table
yi <- log((a * d) / (b * c))
vi <- 1 / a + 1 / b + 1 / c + 1 / d
```

Apply a continuity correction only to zero-cell tables and report the rule.
Reject all-zero event/non-event comparisons. Confirm that group and event order
are consistent because reversing either changes the effect direction.

Back-transform pooled effects and intervals with `exp()`; keep continuous slopes
on the log(OR) scale or interpret `exp(beta)` as the multiplicative OR change per
one moderator unit.

## Custom Effects

Require analysis-scale yi and positive vi. Ask the researcher to document:

- source statistic and conversion formula;
- sampling-variance formula and required assumptions;
- effect direction;
- analysis scale and reporting back-transformation;
- any covariance among effects.

Do not invent formulas for unsupported measures.

## Direction and Validation

Print the minimum, maximum, and selected quantiles of raw and transformed
effects. Investigate impossible values and unusually large `|g| > 3`; do not
delete them solely for being extreme. Compare a representative conversion with
`metafor::escalc()` whenever the input route is supported.

