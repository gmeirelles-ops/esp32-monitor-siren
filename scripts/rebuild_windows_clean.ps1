#Requires -Version 5.1
<#
.SYNOPSIS
  Limpa cache CMake/Flutter e reconstrói o instalador Windows.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\rebuild_windows_clean.ps1
#>
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

Assert-WindowsBuildEnvironment

Write-Host "==> Rebuild limpo - Diponto Sirene Validator"
Write-Host "    Repo: $(Get-RepoRoot)"
Write-Host ""

& (Join-Path $PSScriptRoot "build_windows_all.ps1")
