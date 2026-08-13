# Contributing

Contributions that improve correctness, diagnostics, documentation, or test
coverage are welcome.

## Before opening an issue

1. Confirm that the problem occurs with the current default branch.
2. Reduce the problem to synthetic or de-identified data.
3. Include `sessionInfo()`, the exact call, warnings, and the complete error.
4. State the effect measure, study/effect nesting, and whether the requested
   model is three-level or conventional single-level.

Never attach confidential coding sheets or identifiable participant data.

## Development workflow

```r
install.packages(c("metafor", "testthat"))
install.packages(".", repos = NULL, type = "source")
testthat::test_dir("tests/testthat")
```

Before submitting a pull request, run:

```powershell
R CMD build .
R CMD check --as-cran meta3level_*.tar.gz
```

New behavior must include a focused test. Statistical changes should include a
comparison against direct calls to the underlying package or a hand-verified
formula. Do not silently change effect direction, reference groups, variance
assumptions, missing-data rules, or reporting scales.

## Pull requests

- Keep each pull request focused on one logical change.
- Explain the statistical consequence, not only the code change.
- Update `NEWS.md` and user documentation when behavior changes.
- Preserve the short public `m3*` API and use namespace-qualified calls for
  imported functions.
- Do not include real research data in tests or examples.

