#Requires -Version 5.1
$ErrorActionPreference = "Stop"

Write-Host "==> Gerando pacote portatil (ZIP) e instalador (setup.exe)"
Write-Host ""

& (Join-Path $PSScriptRoot "build_windows_release.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "==> Instalador (Flutter ja compilado; reutiliza Release/)"
Write-Host ""

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

$version = Get-SireneAppVersion
$setupPath = Compile-SireneWindowsInstaller -Version $version

Write-Host ""
Write-Host "Artefatos em dist/:"
Write-Host "  ZIP:        DipontoSireneValidator-$version-win64.zip"
Write-Host "  Instalador: $(Split-Path $setupPath -Leaf)"
