# Troubleshooting

## A CSV is read as one or three columns

The separator or encoding is wrong. Inspect the first lines and try:

```r
raw <- m3read("data.csv", encoding = "auto")
names(raw)
```

If decimal commas are used, set `decimal = ","`. Do not parse a comma-delimited
file with decimal commas unless the file uses a different field separator.

## Empty or duplicate column names

Open the source file and give every column a unique, nonblank heading. Imported
duplicate names may be repaired with positional suffixes; inspect:

```r
attr(raw, "meta3_source")$name_map
```

Map the intended repaired name explicitly.

## No valid effects remain

Check whether numeric cells contain text, whether missing codes were declared,
and whether the required sample sizes or variances are valid. For correlations,
`|r|` must be below 1 and `n` must exceed 3. Sampling variances must be positive.

## The three-level model says no study has repeated effects

Use `level = "single"`. A three-level model cannot separate Level 2 and Level 3
variance when every independent study contributes only one effect.

## The F test still appears under a field named QM

`metafor` stores the omnibus statistic in `QM` for both chi-square and F versions.
Check the model call and summary. It is an F statistic only when `rma.mv` used
`test = "t"` (or legacy `tdist = TRUE`) or when `rma` used a t/F method such as
`test = "knha"`. Do not infer the test family from the object field name alone.

## F and z/QM conclusions differ

The tests use different reference distributions and sometimes different standard
errors or denominator degrees of freedom. With few independent studies, the F
test can be much more conservative. Report the prespecified F analysis rather
than selecting the smaller p-value.

## Spline prediction cannot match a variable named 2 or 3

Build the natural-spline basis explicitly, give its columns stable names, and
reuse the original basis knots and boundary knots for prediction. Do not pass a
bare numeric vector to a model fitted with a multi-column spline basis.

## A variance component is exactly zero

This is a boundary estimate and can be legitimate. Check the number of studies,
repeated effects, model convergence, profile, and one-sided LRT. Do not replace
the value merely because it looks unusually small.

## Egger is significant but trim-and-fill imputes zero studies

The methods target different features. Egger tests an association with precision;
trim-and-fill uses rank-based funnel symmetry under a specific missingness pattern.
Report both and interpret the disagreement instead of treating one as a coding
failure.

## Chinese text fails in a saved PDF

This is usually a graphics-device font issue, not a model issue. Use a font
installed on the system and a Cairo device:

```r
grDevices::cairo_pdf("figure.pdf", width = 8, height = 6)
plot(result)
grDevices::dev.off()
```

## GitHub installation fails

Confirm that the repository owner was substituted in the install command, the
repository is public or credentials are configured, R is at least 4.2, and build
tools are available when source compilation is required. Attach `sessionInfo()`
and the full error when reporting an issue.

