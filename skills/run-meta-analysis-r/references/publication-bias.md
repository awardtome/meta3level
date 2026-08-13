# Publication-Bias and Small-Study-Effect Diagnostics

## Independence First

Classify every method by its required unit:

- Retain effect-level dependence with a multilevel model for multilevel Egger,
  multilevel PET, and multilevel PEESE.
- Use one independent estimate per study for conventional Egger, trim-and-fill,
  rank tests, fail-safe N, and most selection models.
- State the GLS pooling rho when aggregating dependent effects.

## Recommended Core Output

1. Draw the observed study-level funnel plot before trim-and-fill.
2. Fit a study-level Egger model with precision predictor and t/F inference.
3. If requested, run trim-and-fill as a sensitivity analysis and report estimator,
   side, and imputed count.
4. Fit multilevel Egger/PET with SE and multilevel PEESE with variance using
   `test = "t"`.
5. Back-transform intercept estimates only when that intercept represents an
   effect on the analysis scale.
6. Report all estimates, intervals, F tests, study count, and limitations.

## Interpretation

- Say "funnel asymmetry" or "small-study effects" unless publication selection
  is supported by the broader evidence.
- A significant Egger slope does not identify the cause of asymmetry.
- A zero trim-and-fill count does not invalidate a significant Egger slope; the
  methods target different patterns.
- PET and PEESE can be unstable with few independent studies. For standardized
  mean differences, effect size and SE/variance may be mechanically related.
- Do not choose a favorable result by majority vote across diagnostics.
- Present selection models and fail-safe N as supplementary evidence, not as a
  replacement for design, search, and risk-of-bias assessment.

## PET-PEESE Rule

State the prespecified decision rule and show both models. A common rule uses the
PET intercept when it is not distinguishable from zero and examines the PEESE
intercept when PET indicates a nonzero underlying effect. Do not reduce the
analysis to that switch alone; report uncertainty and sensitivity to the
precision predictor and dependence structure.

## Trim-and-Fill Boundary

Run trim-and-fill only on an intercept-only `rma.uni` model with independent
study-level effects. Treat it as sensitivity to one rank-based missingness
mechanism, not a corrected truth.

