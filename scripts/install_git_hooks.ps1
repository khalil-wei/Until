<#!
.SYNOPSIS
Enables this repository's versioned Git hooks for the current local clone.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
& git config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) { throw 'Unable to configure the repository Git hooks path.' }
Write-Host 'Enabled .githooks for this repository clone.'
