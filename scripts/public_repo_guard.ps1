<#!
.SYNOPSIS
Blocks common private files and secrets from entering the Git index.

.DESCRIPTION
With no parameters this script scans staged files, which is how the bundled
pre-commit hook invokes it. Use -AllTracked before making a repository public.
It is deliberately conservative: release credentials belong in local files or
CI secrets, never in a commit.
#>
[CmdletBinding()]
param(
  [switch]$AllTracked
)

$ErrorActionPreference = 'Stop'

$files = if ($AllTracked) {
  & git ls-files
} else {
  & git diff --cached --name-only --diff-filter=ACMR
}

if (-not $files) {
  Write-Host 'Public repository guard: no files to inspect.'
  exit 0
}

$blockedPath = '(?i)(^|/)(local\.properties|signing\.properties|\.env(?:\..+)?|id_rsa(?:\.pub)?|.*\.(p12|p7b|jks|keystore|mobileprovision|cer|pem|key|apk|aab|ipa))$'
$privateKey = '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
$githubToken = '\b(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})\b'
$credentialAssignment = '(?im)^\s*(?:storePassword|keyPassword|clientSecret|apiKey|accessToken|privateKey)\s*[:=]\s*["'']?(?!replace-|<|your-|example|todo|change_me|(?:[A-Za-z0-9_.]+\.)?getProperty\()[^"''\s]{8,}'
$violations = [System.Collections.Generic.List[string]]::new()

foreach ($file in $files) {
  $normalized = $file -replace '\\', '/'
  if ($normalized -match $blockedPath) {
    $violations.Add("Blocked private/release file: $normalized")
    continue
  }

  $content = if ($AllTracked) {
    & git show "HEAD:$normalized" 2>$null
  } else {
    & git show ":$normalized" 2>$null
  }
  $text = [string]::Join("`n", $content)
  if ($text -match $privateKey) { $violations.Add("Private key material: $normalized") }
  if ($text -match $githubToken) { $violations.Add("GitHub token-like value: $normalized") }
  if ($text -match $credentialAssignment) { $violations.Add("Credential assignment: $normalized") }
}

if ($violations.Count -gt 0) {
  Write-Error ("Public repository guard blocked this change:`n - " + ($violations -join "`n - "))
  Write-Error 'Move credentials to local ignored files or GitHub Secrets, then stage the change again.'
  exit 1
}

Write-Host 'Public repository guard passed.'
