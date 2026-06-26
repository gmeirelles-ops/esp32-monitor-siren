#Requires -Version 5.1
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

Assert-WindowsBuildEnvironment

$version = Get-SireneAppVersion

Write-Host "==> Diponto Sirene Validator - build Windows $version"

Invoke-SireneFlutterWindowsBuild
$result = Invoke-SirenePortablePackage

Write-Host ""
Write-Host "Pronto!"
Write-Host "  Pasta: $($result.PackageDir)"
Write-Host "  ZIP:   $($result.ZipPath)"
Write-Host "Copie o ZIP para o pendrive, extraia no PC do posto e execute o arquivo .bat"
