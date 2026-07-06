#Requires -Version 5.1
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "windows_build_common.ps1")
$r = Invoke-SirenePortablePackage
$v = Get-SireneAppVersion
$s = Compile-SireneWindowsInstaller -Version $v
Write-Host ""
Write-Host "ZIP:   $($r.ZipPath)"
Write-Host "Setup: $s"
