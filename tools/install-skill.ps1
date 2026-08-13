param(
  [ValidateSet("codex", "claude")]
  [string]$Target = "codex",
  [ValidateSet("user", "project")]
  [string]$Scope = "user",
  [string]$ProjectPath = (Get-Location).Path,
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "skills\run-meta-analysis-r"

if (-not (Test-Path -LiteralPath (Join-Path $source "SKILL.md"))) {
  throw "Skill source was not found at $source"
}

if ($Scope -eq "project") {
  $base = if ($Target -eq "codex") { ".codex\skills" } else { ".claude\skills" }
  $destinationRoot = Join-Path ([System.IO.Path]::GetFullPath($ProjectPath)) $base
} elseif ($Target -eq "codex") {
  $codexHome = [Environment]::GetEnvironmentVariable("CODEX_HOME")
  if ([string]::IsNullOrWhiteSpace($codexHome)) {
    $codexHome = Join-Path $HOME ".codex"
  }
  $destinationRoot = Join-Path $codexHome "skills"
} else {
  $destinationRoot = Join-Path $HOME ".claude\skills"
}

$destination = Join-Path $destinationRoot "run-meta-analysis-r"
if (Test-Path -LiteralPath $destination) {
  if (-not $Force) {
    throw "Destination already exists: $destination. Re-run with -Force to replace it."
  }
  Remove-Item -LiteralPath $destination -Recurse -Force
}

New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $destination -Recurse

Write-Output "Installed run-meta-analysis-r to: $destination"
Write-Output "Restart the AI application if the skill is not discovered immediately."

