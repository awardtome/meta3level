# Output and Reporting

## Minimum main-effect report

Report the effect measure, transformation, model, estimation method, number of
effects `k`, number of independent studies, pooled estimate, confidence interval,
p-value, and heterogeneity.

Example structure:

> A three-level random-effects model was fitted by REML with effects nested
> within studies. Correlations were transformed to Fisher's z for analysis and
> back-transformed for reporting. The pooled association was r = ..., 95% CI
> [..., ...], p = .... The estimated Level 3 and Level 2 variances were ... and
> ..., corresponding to I-squared values of ...% and ...%. Residual heterogeneity
> was ... .

## Continuous moderator report

Report the centering mean, analysis-scale slope, SE, t, denominator df, p-value,
confidence interval, and omnibus F test. For one moderator, `F = t^2` up to
rounding, but report the F table selected by the analysis plan.

Do not apply `tanh()` to a Fisher-z slope and call it a change in r. Use predicted
effects at meaningful moderator values for interpretation.

## Categorical moderator report

Report:

- reference category;
- effect and study counts per category;
- omnibus F test;
- reference-group intercept and category contrasts;
- no-intercept pooled effect and confidence interval for every category, on the
  reporting scale.

## Nonlinear model report

Report the candidate set, common k/studies, estimation method ML, log likelihood,
AIC, AICc, BIC, delta criterion, and the parsimony rule. Show the observed effects,
selected curve, and confidence band. Treat data-sparse tails cautiously.

## Publication-bias report

Use neutral language such as "funnel asymmetry" or "small-study effects" unless
the full evidence supports a publication-selection interpretation. Report which
methods retain effect-level dependence and which aggregate to one estimate per
study. Explain disagreements rather than voting across tests.

## Leave-one-out report

State the range of pooled estimates and whether direction, significance, or the
substantive conclusion changed. For study-level deletion, report how many effects
each omitted study contributed and how many remained.

## Reporting scales

| Analysis scale | Reporting scale | Back-transformation |
|---|---|---|
| Fisher z | r | `tanh(z)` |
| g | g | none |
| log(OR) | OR | `exp(logOR)` |
| custom | researcher-defined | researcher-defined |

Only pooled effects, no-intercept category effects, predictions, and compatible
intervals should be back-transformed. A continuous slope usually remains on the
analysis scale.

## Reproducibility bundle

Archive:

- the original de-identified coding sheet;
- analysis script;
- generated audit script and minimal RDS sidecar;
- package and dependency versions from `sessionInfo()`;
- figures and result tables;
- decision log for exclusions, direction changes, reference categories, rho,
  continuity corrections, and custom variance formulas.

