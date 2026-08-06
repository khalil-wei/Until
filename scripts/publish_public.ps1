<#!
.SYNOPSIS
Safely publish the private main branch to the public mirror.

The script never pushes by default. Use -Publish after reviewing the diff.
Use -ForceAlign only for the one-time operation that intentionally replaces
the public main history; the old public main is backed up first.
#>
[CmdletBinding()]
param(
  [string]$SourceBranch = 'main',
  [string]$PublicRemote = 'public',
  [string]$PublicBranch = 'main',
  [switch]$Publish,
  [switch]$ForceAlign
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
  $statusLines = @(git status --porcelain)
  if ($statusLines.Count -gt 0) {
    throw 'Working tree is not clean. Commit or stash changes before syncing.'
  }

  $remoteUrl = (@(git remote get-url $PublicRemote 2>$null) -join '').Trim()
  if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
    throw "Remote '$PublicRemote' was not found. Add it first: git remote add $PublicRemote https://github.com/wdlami/Until.git"
  }

  # Run the guard in the current PowerShell process so manual publishing also
  # works on PowerShell Core/Linux without relying on Windows powershell.exe.
  & (Join-Path $repoRoot 'scripts/public_repo_guard.ps1') -AllTracked
  git fetch $PublicRemote

  $sourceSha = (git rev-parse $SourceBranch).Trim()
  $publicRef = "$PublicRemote/$PublicBranch"
  $publicSha = (@(git rev-parse $publicRef 2>$null) -join '').Trim()
  $mergeBase = (@(git merge-base $SourceBranch $publicRef 2>$null) -join '').Trim()

  Write-Host "Source: $SourceBranch ($sourceSha)"
  Write-Host "Public: $publicRef ($publicSha)"
  git diff --stat "$publicRef..$SourceBranch"

  if (-not $mergeBase -and -not $ForceAlign) {
    throw 'The private and public repositories have unrelated histories. Review them, then use -ForceAlign once or use a clean snapshot.'
  }

  if (-not $Publish) {
    Write-Host 'Preview complete. Re-run with -Publish after reviewing the diff.'
    return
  }

  if (-not $mergeBase) {
    $backup = "archive-before-sync-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    git push $PublicRemote "${publicRef}:refs/heads/$backup"
    $lease = "refs/heads/$PublicBranch`:$publicSha"
    git push "--force-with-lease=$lease" $PublicRemote "${SourceBranch}:refs/heads/$PublicBranch"
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to force-align the public branch (exit code $LASTEXITCODE)."
    }
    Write-Host "Backed up public main to $backup and completed the first alignment."
  } else {
    git push $PublicRemote "${SourceBranch}:refs/heads/$PublicBranch"
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to push the public branch (exit code $LASTEXITCODE)."
    }
    Write-Host 'Public repository synced.'
  }
} finally {
  Pop-Location
}
