# Output Contract

## Console

Print, in order:

1. file and sheet information;
2. source rows and columns;
3. retained k, studies, removed rows and reasons;
4. effect-size and moderator summaries;
5. complete `summary()` output for every fitted model;
6. a clearly named F table for moderators;
7. reporting-scale pooled estimates and intervals;
8. multilevel I-squared or conventional heterogeneity;
9. one-sided variance LRTs;
10. spline information criteria;
11. publication-bias and leave-one-out output when requested;
12. warnings, assumptions, and `sessionInfo()`.

Do not replace full model output with a filtered coefficient table when the user
requests console-style results.

## Code

Deliver one complete native R script with:

- one configuration block for file paths and column names;
- namespace-qualified function calls where conflicts are plausible;
- comments that explain statistical blocks rather than obvious assignments;
- no hidden wrapper package;
- deterministic filters and explicit missing-data handling;
- exact model calls used to produce results;
- no automatic package installation unless explicitly requested.

## Figures

Display figures by default. Save only when requested. Use observed effects,
readable axis labels, clear model-line styles, confidence bands where relevant,
and legends that do not cover data. For leave-one-out plots, connect estimates
with a line, overlay points, and add the full-model reference line.

## Tables

When Excel output is requested, create separate sheets/files for distinct
leave-one-effect-out and leave-one-study-out outcomes. Include omitted IDs,
deleted effects, remaining effects, remaining studies, estimate on analysis and
reporting scales, p-value, confidence interval, convergence status, and error
message.

## Reporting Scale

Back-transform only compatible quantities:

| Analysis | Report | Function |
|---|---|---|
| Fisher z | r | `tanh()` |
| Hedges' g | g | identity |
| log(OR) | OR | `exp()` |
| custom | specified by researcher | specified function |

Do not back-transform standard errors directly. Transform confidence limits.

