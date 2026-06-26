#Requires -Version 5.1
<#
.SYNOPSIS
  Atualiza dist/ a partir do build Release ja existente (sem recompilar Flutter).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\sync_dist.ps1
#>
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

Assert-WindowsBuildEnvironment

$version = Get-SireneAppVersion
Write-Host "==> Sincronizando dist/ (versao $version)"

$result = Invoke-SirenePortablePackage

Write-Host ""
Write-Host "Pronto!"
Write-Host "  Pasta: $($result.PackageDir)"
Write-Host "  ZIP:   $($result.ZipPath)"
