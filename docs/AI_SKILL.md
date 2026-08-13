# AI Skill Installation and Usage

The repository contains a standalone Agent Skill at:

```text
skills/run-meta-analysis-r/
```

It does not require the `meta3level` R package. The skill instructs a coding
agent to inspect a coding file and generate direct calls to `metafor`, `splines`,
and other explicitly named R packages. The generated code remains reviewable by
researchers and reviewers.

## Codex

Copy the complete skill directory to:

```text
%USERPROFILE%\.codex\skills\run-meta-analysis-r\
```

or, when `CODEX_HOME` is set:

```text
%CODEX_HOME%\skills\run-meta-analysis-r\
```

Restart Codex if the skill is not discovered in the current session. Invoke it
explicitly as `$run-meta-analysis-r`, or ask for a three-level meta-analysis in R
with r, d, g, OR, moderators, publication-bias diagnostics, or leave-one-out.

From a cloned repository on Windows, installation can be automated:

```powershell
.\tools\install-skill.ps1 -Target codex -Scope user
```

## Claude Code

For a personal skill, copy the folder to:

```text
~/.claude/skills/run-meta-analysis-r/
```

For a project skill, copy it to:

```text
<project>/.claude/skills/run-meta-analysis-r/
```

Invoke `/run-meta-analysis-r` or describe the analysis. Claude Code follows the
Agent Skills `SKILL.md` standard and can load the supporting references and
native R template from the same folder.

```powershell
.\tools\install-skill.ps1 -Target claude -Scope user
```

On Linux or macOS:

```sh
./tools/install-skill.sh codex user
./tools/install-skill.sh claude user
```

## Other AI coding agents

If the agent supports the Agent Skills open directory format, import the full
folder rather than only `SKILL.md`. If it does not, attach `SKILL.md`, the relevant
file under `references/`, and `assets/native-metafor-template.R` to the project
instructions. Discovery paths vary by product, so consult that product's current
official documentation rather than guessing a hidden directory.

## Example prompt

```text
Use $run-meta-analysis-r. Read my coding file, identify the r effect, study ID,
effect ID, sample size, age, year, and design columns, then generate a complete
three-level metafor script. Center age and year, use F tests, fit categorical
intercept/no-intercept models, compare age splines by ML AICc, run one-sided
variance LRTs and both leave-one-out analyses, and print all results in R.
```

## Skill safeguards

The skill must:

- inspect actual names and values before writing mappings;
- ask only when an effect-size definition or design choice cannot be inferred;
- avoid fabricating variance formulas;
- convert r, d, g, and OR on the correct scale;
- use t/F inference rather than relabeling a chi-square QM result;
- center continuous moderators and avoid continuous no-intercept models;
- fit both categorical parameterizations;
- use identical complete cases and ML for spline information criteria;
- distinguish small-study effects from proven publication bias;
- run and validate generated code when the environment permits;
- print native source code and record `sessionInfo()`.

## Skill-only dependencies

The generated script normally uses:

```r
install.packages(c("metafor", "readxl", "openxlsx"))
```

Only install optional packages needed by the selected workflow. The skill does
not install `meta3level` unless the user explicitly chooses the package route.
