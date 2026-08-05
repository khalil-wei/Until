<#!
.SYNOPSIS
Builds a signed Android APK suitable for direct download.

.DESCRIPTION
The signing file is deliberately local-only. This script runs the unit tests,
creates a signed release APK, then writes an SHA-256 checksum beside a copy in
apps/android/release/.
#>
[CmdletBinding()]
param(
  [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$androidRoot = Join-Path $repoRoot 'apps/android'
$signingFile = Join-Path $androidRoot 'signing.properties'

if (-not (Test-Path -LiteralPath $signingFile)) {
  throw "Missing $signingFile. Copy apps/android/signing.properties.example, fill it with the release keystore details, and keep it out of Git."
}

Push-Location $androidRoot
try {
  if (-not $SkipTests) {
    & .\gradlew.bat testDebugUnitTest
    if ($LASTEXITCODE -ne 0) { throw 'Android unit tests failed.' }
  }

  & .\gradlew.bat assembleRelease
  if ($LASTEXITCODE -ne 0) { throw 'Release APK build failed.' }
}
finally {
  Pop-Location
}

$apk = Join-Path $androidRoot 'app/build/outputs/apk/release/app-release.apk'
if (-not (Test-Path -LiteralPath $apk)) {
  throw "Expected signed APK was not produced: $apk"
}

$releaseDirectory = Join-Path $androidRoot 'release'
New-Item -ItemType Directory -Force -Path $releaseDirectory | Out-Null
$targetApk = Join-Path $releaseDirectory 'Until-Android-release.apk'
Copy-Item -LiteralPath $apk -Destination $targetApk -Force
$hash = (Get-FileHash -LiteralPath $targetApk -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$targetApk.sha256" -Value "$hash  Until-Android-release.apk" -Encoding ascii

Write-Host "Direct-download package created: $targetApk"
Write-Host "SHA-256: $hash"
