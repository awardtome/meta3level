param(
  [Parameter(Mandatory = $true)][string]$PackageRoot,
  [Parameter(Mandatory = $true)][string]$ReleaseDirectory,
  [string]$Version = "0.6.2",
  [string]$SkillVersion = "1.0.0"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path -LiteralPath $PackageRoot).Path
$release = [System.IO.Path]::GetFullPath($ReleaseDirectory)
[System.IO.Directory]::CreateDirectory($release) | Out-Null

$githubZip = Join-Path $release ("meta3level-github-v{0}.zip" -f $Version)
$sourceTar = Join-Path $release ("meta3level_{0}.tar.gz" -f $Version)
$skillZip = Join-Path $release ("run-meta-analysis-r-skill-v{0}.zip" -f $SkillVersion)
$manifest = Join-Path $release ("meta3level-整套文件清单-v{0}.txt" -f $Version)
$checksums = Join-Path $release "SHA256SUMS.txt"

$builtTar = Join-Path $root ("meta3level_{0}.tar.gz" -f $Version)
if (-not (Test-Path -LiteralPath $builtTar)) {
  throw "Built R source package not found: $builtTar"
}

function NewZipFromDirectory([string]$SourceDirectory, [string]$Destination,
                             [string]$TopDirectory, [scriptblock]$Include) {
  if (Test-Path -LiteralPath $Destination) {
    Remove-Item -LiteralPath $Destination -Force
  }
  $stream = [System.IO.File]::Open($Destination, [System.IO.FileMode]::CreateNew)
  $archive = New-Object System.IO.Compression.ZipArchive(
    $stream,
    [System.IO.Compression.ZipArchiveMode]::Create,
    $false,
    [System.Text.Encoding]::UTF8
  )
  try {
    Get-ChildItem -LiteralPath $SourceDirectory -Recurse -File -Force |
      Where-Object { & $Include $_ } |
      Sort-Object FullName |
      ForEach-Object {
        $relative = $_.FullName.Substring($SourceDirectory.Length).TrimStart('\', '/')
        $entryName = ($TopDirectory.TrimEnd('/', '\') + '/' +
                      ($relative -replace '\\', '/'))
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
          $archive, $_.FullName, $entryName,
          [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
      }
  } finally {
    $archive.Dispose()
    $stream.Dispose()
  }
}

$packageFilter = {
  param($file)
  $relative = $file.FullName.Substring($root.Length).TrimStart('\', '/')
  $relativeUnix = $relative -replace '\\', '/'
  return $relativeUnix -notmatch '(^|/)([.]Rproj[.]user|[.]git)(/|$)' -and
         $relativeUnix -notmatch '[.]Rcheck/' -and
         $relativeUnix -notmatch '[.]tar[.]gz$' -and
         $relativeUnix -notmatch '[.]log$'
}

$skillRoot = Join-Path $root "skills\run-meta-analysis-r"
$skillFilter = { param($file) $true }

NewZipFromDirectory $root $githubZip "meta3level" $packageFilter
NewZipFromDirectory $skillRoot $skillZip "run-meta-analysis-r" $skillFilter
Copy-Item -LiteralPath $builtTar -Destination $sourceTar -Force
Copy-Item -LiteralPath (Join-Path $root "RELEASE_NOTES.md") -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $root "RELEASE_NOTES.zh-CN.md") -Destination $release -Force

$packageFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
  Where-Object { & $packageFilter $_ } |
  ForEach-Object { $_.FullName.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/' } |
  Sort-Object
$releaseFiles = Get-ChildItem -LiteralPath $release -File -Force |
  Where-Object { $_.Name -ne (Split-Path -Leaf $manifest) -and
                 $_.Name -ne (Split-Path -Leaf $checksums) } |
  Select-Object -ExpandProperty Name |
  Sort-Object

$manifestLines = @(
  "meta3level v$Version exact file manifest",
  "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
  "",
  "[GitHub repository: meta3level/]"
) + ($packageFiles | ForEach-Object { "meta3level/$_" }) + @(
  "",
  "[Release directory]"
) + $releaseFiles + @(
  (Split-Path -Leaf $manifest),
  (Split-Path -Leaf $checksums)
)
[System.IO.File]::WriteAllLines($manifest, $manifestLines,
                                (New-Object System.Text.UTF8Encoding($true)))

$deliverables = Get-ChildItem -LiteralPath $release -File -Force |
  Where-Object { $_.Name -ne "SHA256SUMS.txt" } |
  Sort-Object Name
$checksumLines = foreach ($file in $deliverables) {
  $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  "$hash  $($file.Name)"
}
[System.IO.File]::WriteAllLines($checksums, $checksumLines,
                                (New-Object System.Text.UTF8Encoding($false)))

Write-Output ("GITHUB_ZIP={0}" -f $githubZip)
Write-Output ("SOURCE_TAR={0}" -f $sourceTar)
Write-Output ("SKILL_ZIP={0}" -f $skillZip)
Write-Output ("MANIFEST={0}" -f $manifest)
Write-Output ("CHECKSUMS={0}" -f $checksums)
Write-Output ("REPOSITORY_FILES={0}" -f $packageFiles.Count)
Write-Output ("RELEASE_FILES={0}" -f (Get-ChildItem -LiteralPath $release -File).Count)
