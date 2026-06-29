#Requires -Version 5.1
<#
.SYNOPSIS
  Limpa cache CMake/Flutter e reconstrói o instalador Windows.

  Use quando flutter build windows falhar em flutter_wrapper_app.vcxproj,
  especialmente se o projeto estiver em OneDrive\Área de Trabalho.

.EXAMPLE
  # Se o projeto tem acento no caminho, crie junction primeiro (cmd como admin):
  # mklink /J C:\dev\diponto-sirene "C:\Users\gmeir\OneDrive\Área de Trabalho\diponto\firmware\esp32-monitor-siren"
  # cd C:\dev\diponto-sirene
  powershell -ExecutionPolicy Bypass -File scripts\rebuild_windows_clean.ps1
#>
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

Assert-WindowsBuildEnvironment

Write-Host "==> Rebuild limpo — Diponto Sirene Validator"
Write-Host "    Repo: $(Get-RepoRoot)"
Write-Host ""

& (Join-Path $PSScriptRoot "build_windows_all.ps1")
