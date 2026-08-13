# Data Requirements

## Core identifiers

Every retained row must have:

| Field | Meaning |
|---|---|
| Study ID | Statistically independent sample or cluster |
| Effect ID | Unique effect within the study |
| Effect input | r, d, g, OR, or custom yi |
| Uncertainty input | Required sample sizes, SE/CI, table cells, or vi |

One publication can contain multiple independent samples and therefore multiple
study IDs. Conversely, multiple effects computed from the same sample must share
one study ID.

## Supported effect measures

### Correlation r

Required: `r`, total `n`. The package computes Fisher's z and
`vi = 1 / (n - 3)`. Values with `|r| >= 1` or `n <= 3` are invalid.

### Independent-groups d

Required: Cohen's d, intervention `n1`, control `n2`. The package applies the
exact gamma-function Hedges correction and analyzes g. If a valid d variance is
provided, it is transformed; otherwise the documented independent-groups SMD
variance is used.

Confirm the effect direction before analysis. Reversing group order reverses g.

### Precomputed g

Preferred input: Hedges' g plus its sampling variance. Do not place a standard
error in a variance column. The package warns, but does not delete, `|g| > 3`.

### Single-group or pre-post d/g

Provide a design-specific sampling variance. Pre-post effects usually require a
pre-post correlation and depend on the exact standardization. If no valid
variance exists, do not silently apply an independent-groups formula. The package
allows an explicit approximate fallback only as a disclosed sensitivity model.

### Odds ratio

Use exactly one of:

- OR plus log(OR) variance;
- OR plus log(OR) standard error;
- OR plus lower and upper confidence limits;
- a complete 2 by 2 table.

The event definition and group order must remain identical across rows. For
zero-cell tables, the default continuity correction is applied only to tables
containing at least one zero.

### Custom effect

Provide analysis-scale `yi` and sampling variance `vi`. The study report must
state the source and transformation formula, assumptions, direction, and
reporting-scale back-transformation.

## Moderator variables

Researchers decide which variables are continuous and categorical before
modeling.

- Continuous moderators must be numerically meaningful and are centered using
  the mean of rows retained for that moderator.
- Continuous moderators do not use a no-intercept model.
- Categorical moderators require an explicit reference category.
- Categorical analyses fit an intercept model for contrasts and a no-intercept
  model for category-specific pooled effects.
- A study-level moderator should not contain conflicting values within one
  study when running a conventional single-level analysis.

## Percentages

Choose one scale and document it: proportions from 0 to 1 or percentage points
from 0 to 100. Mixed strings such as `52%` and numeric values require careful
review. Ambiguous mixtures such as `1` and `50%` should be resolved manually.

## Missing data and identifiers

- Blank study/effect IDs are invalid.
- Each study/effect pair must be unique.
- Invalid yi, nonpositive vi, and required missing values are removed with a
  count in the console.
- Do not encode missing values as zero unless zero is a real value.
- Preserve original row IDs so exclusions can be audited.

## Sampling covariance

The default three-level model uses a diagonal sampling-variance vector. Random
effects address heterogeneity and dependence in true effects; they do not
automatically reproduce known sampling covariance from shared participants,
shared controls, or algebraically related outcomes. If that covariance can be
constructed, use a design-specific V matrix in a direct `metafor` analysis.

