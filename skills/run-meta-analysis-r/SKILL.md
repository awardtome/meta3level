---
name: run-meta-analysis-r
description: Inspect research coding files and generate, run, debug, and explain complete auditable R code for three-level or conventional meta-analysis without requiring the meta3level package. Use for CSV/Excel/SPSS-style coding sheets containing correlations, Cohen's d, Hedges' g, odds ratios, or researcher-defined yi/vi; main effects, multilevel I-squared, one-sided variance LRTs, centered continuous moderators, categorical intercept/no-intercept models, ML spline comparisons, publication-bias or small-study-effect diagnostics, PET-PEESE, funnel/forest/moderator plots, and leave-one-effect/study-out sensitivity analyses. Also use when users require metafor t/F tests instead of chi-square QM tests, full console output, or the native underlying R code for review.
---

# Run Meta-Analysis in R

Generate native, reviewable R code that calls `metafor` and named supporting
packages directly. Do not require or silently install `meta3level`.

## Follow This Workflow

1. Inspect the actual file, sheet names, dimensions, column names, duplicate or
   blank headings, first rows, missing codes, and unique values of candidate
   categorical variables.
2. Identify the independent study/sample ID, effect ID, effect definition,
   uncertainty inputs, effect direction, and nesting. Treat publication ID and
   independent sample ID as different concepts.
3. Determine whether the effect is r, independent-groups d, precomputed g, OR,
   or custom yi/vi. Read [effect-sizes.md](references/effect-sizes.md) before
   selecting a formula.
4. Confirm any choice that cannot be recovered safely: pre-post variance,
   custom effect formula, event/group direction, multiple plausible columns,
   reference category, or whether samples are independent. Do not ask about
   choices that the file or request already answers.
5. Copy and tailor [native-metafor-template.R](assets/native-metafor-template.R).
   Replace every configuration placeholder and delete unused branches from the
   delivered script.
6. Apply explicit filters, convert numeric columns deliberately, and print a
   data-retention audit: source rows, retained k, removed rows and reasons,
   independent studies, repeated effects, ranges, and category counts.
7. Fit the requested model and print complete `summary()` output. Follow
   [models-and-tests.md](references/models-and-tests.md) for F inference,
   heterogeneity, moderators, splines, and single-level pooling.
8. Run requested diagnostics and plots. Follow
   [publication-bias.md](references/publication-bias.md) for independence and
   interpretation requirements.
9. Run the script when R and the data are available. Resolve syntax, column,
   singularity, prediction-basis, and output errors rather than handing an
   untested script to the user.
10. Check numerical results against a direct alternative calculation where
    practical, then apply [quality-gates.md](references/quality-gates.md).
11. Return the complete native script, essential results, assumptions, warnings,
    and `sessionInfo()`. Use [output-contract.md](references/output-contract.md)
    for console, tables, figures, and reporting scales.

## Choose the Analysis Level

- Use a three-level model only when at least two independent studies exist and
  at least one study contributes repeated effects. Prefer more than one repeated-
  effect study before interpreting Level 2 variance as stable.
- Use a conventional random-effects model when each study contributes one
  independent effect.
- If a conventional analysis starts with dependent effects, first pool to one
  effect per study by GLS under an explicitly reported rho. Repeat plausible rho
  values such as 0, .30, .60, and .90.
- If known sampling covariance exists from shared participants, shared controls,
  or algebraic dependence, construct the design-specific V matrix. Do not claim
  that nested random effects alone replace known sampling covariance.

## Enforce the Inference Rules

- For `rma.mv`, use `test = "t"` so coefficients use t tests and the moderator
  omnibus test uses F. Legacy `tdist = TRUE` is acceptable only when reproducing
  existing code.
- For `rma`, use `test = "knha"` unless the user specifies a justified method.
- Extract the omnibus statistic from `model$QM`, but label it F only after
  verifying the fitted model uses t/F inference. Include numerator and
  denominator degrees of freedom.
- Center every continuous moderator using the mean of its retained complete-case
  analysis sample. Fit no continuous no-intercept model.
- For each categorical moderator, relevel to the requested reference, fit an
  intercept model for contrasts and omnibus F, then a no-intercept model for
  category-specific pooled effects.
- Fit spline candidates on identical complete cases with ML. Compare linear and
  prespecified natural-spline degrees of freedom using logLik, AIC, AICc, and
  BIC. Prefer the simpler candidate among models within delta AICc <= 2 unless
  theory supports greater complexity.
- Use one-sided boundary LRT p-values for variance components and state the
  0.5 chi-square(0) + 0.5 chi-square(1) reference approximation.

## Preserve Reporting Scales

- Analyze r as Fisher z; back-transform pooled effects, category means,
  predictions, and compatible intervals with `tanh()`.
- Convert d to Hedges' g before modeling; report pooled effects as g.
- Analyze OR as log(OR); exponentiate pooled effects, category means,
  predictions, and compatible intervals.
- Keep continuous slopes on their analysis scale. Never call `tanh(z slope)` a
  change in r or `exp(logOR slope)` a raw OR difference without explaining the
  multiplicative interpretation.
- Require the researcher to define the reporting transformation for custom yi.

## Work Safely

- Never overwrite the original coding file.
- Do not upload, publish, or bundle real data without explicit permission.
- Use synthetic data in reusable examples and tests.
- Do not search moderator groupings or category combinations merely to obtain
  significance. If exploratory searches are requested, label them exploratory,
  show the complete search space, and address multiplicity.
- Do not equate a significant Egger/PET slope with proven publication bias.
- Do not hide warnings, dropped rows, failed models, boundary estimates, sparse
  categories, or denominator degrees of freedom.
- Do not save files unless requested. When saving, use explicit paths and report
  every created artifact.

## Deliver a Reproducible Result

Provide one complete script rather than disconnected snippets. Put all user-
replaceable mappings in one configuration block, explain each block with short
comments, print full models in the console, and end with `sessionInfo()`.

When the user only requests code, still validate syntax and mappings when the
data are available. When the user requests execution, run end to end and report
the exact retained k/study counts and any unresolved statistical limitation.

