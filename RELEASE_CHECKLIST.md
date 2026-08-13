# Release Checklist

## Release identity

The public metadata for version 0.6.2 is finalized as follows:

- GitHub owner and software author: `awardtome`.
- Maintainer email: `awardtome@users.noreply.github.com`.
- Repository: `https://github.com/awardtome/meta3level`.
- Copyright holder: `awardtome`.
- `.github/FUNDING.yml` is intentionally omitted; add it only if needed.

## Repository preparation

1. Confirm the GitHub repository is named `meta3level`.
2. Copy this directory to the repository root without omitting hidden files.
3. Confirm `DESCRIPTION` contains:

```text
URL: https://github.com/awardtome/meta3level
BugReports: https://github.com/awardtome/meta3level/issues
```

4. Review the license and citation metadata.
5. Confirm the synthetic example contains no real study data.

## Quality gates

```powershell
Rscript tools/check-repository.R
Rscript tools/check-manual-code.R USER_MANUAL.zh-CN.md
Rscript tools/smoke-test-native-template.R
Rscript tools/smoke-test-user-manual.R .
R CMD build .
R CMD check --as-cran --no-manual meta3level_0.6.2.tar.gz
```

- Require zero errors, warnings, and notes unless a note is documented and
  understood.
- Run every script under `examples/`.
- Validate `skills/run-meta-analysis-r` with the skill validator.
- Test package installation in a clean R library.
- Confirm `m3code()` produces runnable native audit code.
- Rebuild the DOCX/PDF manual and visually inspect all rendered pages.

## GitHub release

1. Commit the checked source.
2. Push the default branch and confirm all CI jobs pass.
3. Tag `v0.6.2`.
4. Create a GitHub release from that tag.
5. Attach the R source archive, standalone Skill ZIP, Chinese DOCX/PDF manual,
   exact file-tree manifest, and `SHA256SUMS.txt`.
6. Record or link the SHA-256 hashes in the release notes.
