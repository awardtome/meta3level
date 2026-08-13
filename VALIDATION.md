# Validation Record

Validation date: 2026-08-13  
Package version: 0.6.2  
Local platform: Windows 11, R 4.5.1

## Package checks

- `R CMD build` completed successfully.
- `R CMD check --as-cran --no-manual` completed with 0 errors, 0 warnings,
  and 2 documented environment/release notes. The notes concern new-submission
  status and inability to verify the online clock in the local environment.
  Installation, namespace, documentation, code, and tests passed.
- The full `testthat` suite completed with no failed expectations. Expected
  safety warnings cover small study counts, explicit row removal, and assumed
  within-study correlations.
- Installation into an isolated R library succeeded.
- Every script under `examples/` ran after installation.

## Native R template checks

The package-independent Skill template parsed and ran for all of these cases:

- correlation transformed to Fisher's z in a three-level model;
- independent-groups Cohen's d transformed to Hedges' g;
- precomputed Hedges' g with known sampling variance;
- odds ratio from a two-by-two table;
- researcher-defined `yi` and `vi`;
- conventional random-effects correlation analysis after study-level pooling.

The official Skill quick validator accepted `skills/run-meta-analysis-r`, and
`agents/openai.yaml` was parsed independently as YAML.

## Real coding-sheet compatibility audit

Two user-provided coding sheets were tested outside the repository and are not
distributed:

- a correlation coding sheet with cold- and hot-executive-function subsets;
- a Cohen's d coding sheet with within-intervention and intervention-control
  outcomes converted to Hedges' g.

All four branches fitted a three-level main model through the short public API.
Requested continuous and categorical moderators, ML spline comparisons, and
both leave-one-out analyses completed without captured component errors. The
d-to-g branches also completed the publication-bias workflow. No real data,
absolute source path, or substantive result is stored in this repository.

## Repository checks

- All R files parse.
- Local Markdown links resolve.
- GitHub workflow and issue-template YAML files parse.
- The PowerShell Skill installer produced the required directory structure.
- The Unix Skill installer passed `bash -n` syntax validation.
- Public author, maintainer, copyright, repository, and installation metadata
  are internally consistent, with no release identity placeholders remaining.

## User manual checks

- All 61 fenced R code blocks in `USER_MANUAL.zh-CN.md` and all 75 fenced R
  code blocks in `USER_MANUAL.en.md` parsed successfully.
- The user-manual smoke test completed the three-level and conventional
  single-level workflows, continuous and categorical moderators, ML spline
  comparison, PET-PEESE, both leave-one-out analyses, plots, d-to-g conversion,
  and odds-ratio preparation.
- Word generated a 41-page Chinese DOCX/PDF and a 40-page English DOCX/PDF,
  each with one automatic table of contents. All 81 pages were rendered to PNG
  and visually inspected; no overlap, clipped code, table overflow, blank-page
  anomaly, or CJK rendering failure was found.
- Both complete manuals and both concise function references cover all 18
  functions exported in `NAMESPACE`. Repository validation checks this coverage
  automatically.

This record documents software behavior on the stated platform. GitHub Actions
repeats package checks on current Windows, macOS, and Ubuntu runners and on
multiple R release channels after the repository is pushed.
