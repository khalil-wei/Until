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

  # Run the guard in the current PowerShell process so the publisher works on
  # both GitHub's Ubuntu runners (PowerShell Core) and Windows development
  # machines without relying on the Windows-only `powershell.exe` binary.
  & (Join-Path $repoRoot 'scripts/public_repo_guard.ps1') -AllTracked
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

  # This workflow is private-repository-only. Do not copy it to the public
  # mirror, where it would run without the private repository secret.
  $privateOnlyFiles = @('.github/workflows/publish-public.yml')
  foreach ($file in $privateOnlyFiles) {
    $path = Join-Path $cloneRoot $file
    if (Test-Path -LiteralPath $path -PathType Leaf) {
      Remove-Item -LiteralPath $path -Force
    }
  }

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

  # GitHub-hosted runners do not provide a Git identity by default. Configure
  # one only in the temporary public clone so the sync commit is reproducible
  # without changing the developer's global Git configuration.
  git -C $cloneRoot config user.name 'CountdownCalendar Sync'
  git -C $cloneRoot config user.email 'actions@users.noreply.github.com'
  git -C $cloneRoot commit -m "sync: publish private snapshot $($sourceSha.Substring(0, 7))"
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to create the public sync commit (exit code $LASTEXITCODE)."
  }
  git -C $cloneRoot push origin "HEAD:refs/heads/$PublicBranch"
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to push the public sync commit (exit code $LASTEXITCODE)."
  }
  Write-Host 'Public snapshot published without private Git history.'
} finally {
  Pop-Location
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
