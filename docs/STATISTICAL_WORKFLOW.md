# Statistical Workflow

## Primary sequence

1. Confirm independent study IDs and unique effect IDs.
2. Transform the chosen effect measure to its analysis scale.
3. Fit the intercept-only model.
4. Report the pooled effect on its reporting scale and residual heterogeneity.
5. Decompose Level 2 and Level 3 I-squared for three-level models.
6. Run one-sided boundary LRTs for variance components.
7. Analyze prespecified moderators.
8. Compare prespecified nonlinear models using identical data and ML.
9. Assess small-study effects using several diagnostics, not one binary test.
10. Run leave-one-effect-out and leave-one-study-out sensitivity analyses.
11. Preserve native code, prepared data, software versions, and assumptions.

## Three-level model

The core model is equivalent to:

```r
metafor::rma.mv(
  yi, V = vi,
  random = ~ 1 | studyID/effectID,
  method = "REML",
  test = "t",
  data = dat
)
```

The package currently uses `tdist = TRUE`, retained by `metafor` for backward
compatibility and equivalent to t/F inference. In modern native code, prefer
`test = "t"`. Under this setting, individual coefficients use t tests and the
omnibus moderator statistic stored internally as `QM` is reported as an F test.
Do not relabel a model fitted with `test = "z"` as F.

## Heterogeneity

Report:

- Level 3 between-study variance;
- Level 2 within-study between-effect variance;
- the corresponding I-squared proportions;
- residual `QE` and its p-value;
- one-sided boundary LRTs, with the mixture reference distribution disclosed.

A near-zero estimated variance is a boundary estimate, not proof that the true
component is exactly zero. Very few studies or few studies with repeated effects
can make component estimates unstable.

## Continuous moderators

- Use complete cases for that moderator.
- Center at the retained-sample mean.
- Fit one intercept model only.
- Interpret the intercept as the pooled effect at the mean moderator value.
- Interpret the slope on the analysis scale: Fisher z for correlations, g units
  for SMDs, and log(OR) for odds ratios.
- Use the omnibus F result from the fitted t/F model.

## Categorical moderators

- Relevel the factor to the prespecified reference category.
- Fit an intercept model for category contrasts and the omnibus F test.
- Fit a no-intercept model for pooled effects in all categories.
- Back-transform category pooled effects where appropriate.
- Report the number of effects and independent studies per category.

## Nonlinear moderators

Natural-spline candidates must use exactly the same complete-case rows and ML,
not REML, for AIC/AICc/BIC comparison. Compare the conventional linear model and
prespecified spline degrees of freedom. When several models have delta AICc no
larger than 2, prefer the simpler model unless substantive theory justifies added
complexity. High degrees of freedom relative to the study count are exploratory.

## Conventional single-level model

When each study contributes one independent effect, use a conventional random-
effects model. If a study contributes dependent effects but the analysis must be
single-level, pool within study under a stated sampling correlation rho, then fit:

```r
metafor::rma(yi, vi, method = "REML", test = "knha", data = studyDat)
```

Repeat plausible rho values because rho is an assumption, not estimated from the
effect-size table.

## Publication-bias and small-study-effect diagnostics

- Funnel asymmetry and Egger tests indicate small-study effects, not a proven
  publication process.
- Multilevel Egger/PET-PEESE can retain dependent effects, but interpretation
  must acknowledge effect-SE mechanical association for SMDs.
- Methods requiring independent effects should use one estimate per study.
- Trim-and-fill is a sensitivity analysis for a particular asymmetry mechanism,
  not a universal correction.
- A trim-and-fill estimate of zero missing studies can coexist with a significant
  Egger slope because the methods test different patterns.
- PET/PEESE should be reported with their model, scale, F test, and uncertainty;
  do not report only whether one p-value crossed .05.

## Sensitivity analysis

Leave-one-effect-out detects individual effect influence while retaining other
effects from the same study. Leave-one-study-out removes every effect from one
independent study and is the stronger cluster-level check. Report deleted IDs,
remaining k/studies, pooled estimate, p-value, and confidence interval.

