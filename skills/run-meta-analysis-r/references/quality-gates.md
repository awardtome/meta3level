# Quality Gates

Complete every applicable gate before delivery.

## Data Gate

- Verify actual column names and positions.
- Detect blank/duplicate headings and one-column delimiter failures.
- Confirm study IDs represent independent samples.
- Confirm unique study/effect pairs.
- Print exclusions by reason.
- Check effect direction and variable ranges.
- Resolve ambiguous percentage scales.

## Formula Gate

- Compare r, independent d/g, or OR conversions with a representative
  `metafor::escalc()` calculation.
- Require positive finite sampling variances.
- Refuse an unsupported pre-post or custom variance formula.
- Confirm all back-transformations match the analysis scale.

## Model Gate

- Confirm a three-level structure is identifiable from the data.
- Use `test = "t"` for `rma.mv` F inference and `test = "knha"` for conventional
  `rma` unless justified otherwise.
- Verify the displayed F statistic, df1, df2, and p-value come from that model.
- Check convergence warnings and boundary estimates.
- Use identical complete cases and ML for spline comparisons.
- Check that spline prediction reuses original knots and boundary knots.

## Sensitivity Gate

- Ensure study-level methods contain one independent estimate per study.
- Report the aggregation rho and test plausible alternatives.
- Run both leave-one-effect-out and leave-one-study-out when requested.
- Preserve failed deletion rows with error text instead of dropping them.
- Check whether any deletion changes direction or substantive inference.

## Reproducibility Gate

- Parse and run the final script when possible.
- Re-run from a clean R session when feasible.
- Keep source data unchanged.
- Record package versions with `sessionInfo()`.
- Return the exact script used, not a reconstructed approximation.
- State tests or optional methods that could not run and why.

