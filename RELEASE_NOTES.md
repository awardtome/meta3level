# meta3level 0.6.2

This release provides an auditable R workflow for three-level and conventional
meta-analysis and a standalone Agent Skill for researchers who prefer native
`metafor` code instead of an R-package wrapper.

## Included files

- `meta3level-github-v0.6.2.zip`: complete GitHub-ready repository.
- `meta3level_0.6.2.tar.gz`: installable R source package.
- `run-meta-analysis-r-skill-v1.0.0.zip`: standalone AI Skill.
- `meta3level-user-manual-zh-CN-v0.6.2.docx`: complete Chinese Word manual.
- `meta3level-user-manual-zh-CN-v0.6.2.pdf`: complete Chinese PDF manual.
- `meta3level-user-manual-en-v0.6.2.docx`: complete English Word manual.
- `meta3level-user-manual-en-v0.6.2.pdf`: complete English PDF manual.
- `meta3level-file-manifest-v0.6.2.txt`: exact repository and release file tree.
- `SHA256SUMS.txt`: SHA-256 checksums for the main deliverables.

The repository also includes `FUNCTION_REFERENCE.en.md` and
`FUNCTION_REFERENCE.zh-CN.md`, concise references covering all 18 exported
functions with their purpose, principal arguments, returned objects, examples,
and common cautions.

## Validation

- `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, and 2 documented
  environment/release notes. They concern new-submission status and unavailable
  online clock verification. Installation,
  namespace, documentation, code, and tests passed.
- Full `testthat` suite: no failed expectations.
- Four public examples: passed after isolated installation.
- Native Skill template: passed for r, d-to-g, precomputed g, OR, custom yi/vi,
  and conventional single-level analysis.
- Official Skill validator: passed.
- Two real coding-sheet compatibility audits: all four analysis branches
  completed through the short public API without captured component errors.
- Manual QA: all 61 Chinese and 75 English fenced R code blocks parsed. The
  documented major analysis paths passed an executable smoke test, and all 41
  Chinese plus 40 English PDF pages passed visual inspection.
- Documentation coverage: all 18 exported functions are described in both
  complete manuals and both concise function references.

See `VALIDATION.md` for the complete validation scope.

## Public release metadata

Version 0.6.2 is published by `awardtome` at
`https://github.com/awardtome/meta3level`. The package uses the GitHub noreply
maintainer address to avoid exposing a private email. Public metadata and
installation links were rechecked before the release archives were rebuilt.

No user research data are included in any archive.
