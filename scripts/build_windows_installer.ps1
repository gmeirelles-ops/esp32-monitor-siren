#Requires -Version 5.1
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

Assert-WindowsBuildEnvironment

$version = Get-SireneAppVersion

Write-Host "==> Diponto Sirene Validator - instalador Windows $version"

Invoke-SireneFlutterWindowsBuild
$setupPath = Compile-SireneWindowsInstaller -Version $version

Write-Host ""
Write-Host "Pronto!"
Write-Host "  Instalador: $setupPath"
Write-Host "Execute o setup no PC do posto para instalar em Program Files."
