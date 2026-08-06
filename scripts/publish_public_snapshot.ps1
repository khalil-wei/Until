<#!
.SYNOPSIS
Publish only the current tracked source snapshot to the public repository.

This keeps private Git history private. The public repository keeps its own
history and receives one normal sync commit on top of its current branch.
The script previews by default; add -Publish to push.
#>
[CmdletBinding()]
param(
  [string]$SourceBranch = 'main',
  [string]$PublicUrl = 'https://github.com/wdlami/Until.git',
  [string]$PublicBranch = 'main',
  [switch]$Publish
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("until-public-snapshot-" + [guid]::NewGuid().ToString('N'))
$cloneRoot = Join-Path $tempRoot 'public'
$archive = Join-Path $tempRoot 'source.tar'

Push-Location $repoRoot
try {
  $statusLines = @(git status --porcelain)
  if ($statusLines.Count -gt 0) {
    throw 'Working tree is not clean. Commit or stash changes before publishing.'
  }

  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$repoRoot\scripts\public_repo_guard.ps1" -AllTracked
  $sourceSha = (git rev-parse $SourceBranch).Trim()
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
  git archive --format=tar --output="$archive" $SourceBranch
  git clone --branch $PublicBranch --single-branch $PublicUrl $cloneRoot

  # Remove the public working tree while leaving its .git directory intact.
  git -C $cloneRoot clean -fdx
  $publicFiles = @(git -C $cloneRoot ls-files)
  foreach ($file in $publicFiles) {
    $path = Join-Path $cloneRoot $file
    if (Test-Path -LiteralPath $path -PathType Leaf) {
      Remove-Item -LiteralPath $path -Force
    }
  }
  tar -xf $archive -C $cloneRoot

  git -C $cloneRoot add -A
  $changes = @(git -C $cloneRoot status --short)
  Write-Host "Source snapshot: $sourceSha"
  if ($changes.Count -eq 0) {
    Write-Host 'Public repository already matches the source snapshot.'
    return
  }
  $changes | Select-Object -First 80

  if (-not $Publish) {
    Write-Host "Preview complete. Temporary public clone: $cloneRoot"
    Write-Host 'Re-run with -Publish after reviewing the listed changes.'
    return
  }

  git -C $cloneRoot commit -m "sync: publish private snapshot $($sourceSha.Substring(0, 7))"
  git -C $cloneRoot push origin "HEAD:refs/heads/$PublicBranch"
  Write-Host 'Public snapshot published without private Git history.'
} finally {
  Pop-Location
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
