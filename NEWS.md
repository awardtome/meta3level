# meta3level 0.6.2

- Added three-level and conventional random-effects workflows for correlations,
  Cohen's d, Hedges' g, odds ratios, and custom effect sizes.
- Added small-sample t/F inference through `metafor`, centered continuous
  moderators, categorical intercept/no-intercept models, and ML spline model
  comparison.
- Added multilevel I-squared decomposition and one-sided likelihood-ratio tests
  for variance components.
- Added multilevel and study-level small-study-effect diagnostics, PET-PEESE,
  optional selection-model diagnostics, and funnel plots.
- Added leave-one-effect-out and leave-one-study-out analyses with connected
  plots and complete result tables.
- Added conventional meta-analysis with generalized least-squares pooling of
  dependent effects within studies.
- Added auditable native R code generation through `m3code()` and installed
  source inspection through `m3source()`.
- Added strict checks for duplicate identifiers, malformed numeric columns,
  ambiguous percentages, unsupported single-group SMD variances, and extreme g.
- Added GitHub release documentation, cross-platform CI, a repository checker,
  executable examples, and a standalone Agent Skill with native `metafor` code.
- Allowed `m3plot()` to select continuous and spline workflow results by either
  their display name or their original moderator column name.
