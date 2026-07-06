#Requires -Version 5.1
<#
.SYNOPSIS
  Monta pacote completo no pendrive: app win64 + scripts USB + (opcional) export dos dados deste PC.

.EXAMPLE
  powershell -File scripts\preparar_usb_posto.ps1 -UsbRoot E:\DipontoPosto -ExportarDestePc -SemSync
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$UsbRoot,
    [switch]$ExportarDestePc,
    [string]$StationId,
    [switch]$SemSync,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows_build_common.ps1')

$portableTemplates = Join-Path $PSScriptRoot 'windows-portable'
$usbRoot = $UsbRoot.TrimEnd('\')

if (-not $SkipBuild) {
    $releaseDir = Get-SireneReleaseDir
    if (-not (Test-Path (Join-Path $releaseDir 'sirene_app.exe'))) {
        Write-Host '==> Build release...'
        Invoke-SireneFlutterWindowsBuild
    }
}

$pkg = Invoke-SirenePortablePackage -SkipZip
$version = $pkg.Version

# Copiar pacote portátil para o USB (ou mesclar se já existir pasta versionada)
if ((Split-Path $usbRoot -Leaf) -match '^DipontoSireneValidator-') {
    $destRoot = $usbRoot
} else {
    $destRoot = Join-Path $usbRoot "DipontoSireneValidator-$version-win64"
}

Write-Host "==> Destino USB: $destRoot"
if (Test-Path $destRoot) {
    Remove-Item $destRoot -Recurse -Force
}
Copy-Item $pkg.PackageDir $destRoot -Recurse -Force

$usbScripts = @(
    'posto_usb_paths.ps1',
    'exportar_posto_usb.ps1',
    'instalar_posto_do_usb.ps1',
    'Instalar no PC.bat',
    'Exportar dados para USB.bat',
    'LEIA-ME-USB-POSTO.txt',
    'Diagnostico-Posto.ps1'
)
foreach ($name in $usbScripts) {
    $src = Join-Path $portableTemplates $name
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $destRoot $name) -Force
    }
}

if ($ExportarDestePc) {
    Write-Host '==> Exportando dados locais para dados_posto\'
    $exportArgs = @{
        PackageRoot = $destRoot
    }
    if ($StationId) { $exportArgs['StationId'] = $StationId }
    if ($SemSync) { $exportArgs['SemSync'] = $true }
    & (Join-Path $portableTemplates 'exportar_posto_usb.ps1') @exportArgs
} else {
    Write-Host 'Dica: configure o app neste PC e rode Exportar dados para USB.bat no pendrive.'
}

Write-Host ''
Write-Host "Pacote USB pronto: $destRoot" -ForegroundColor Green
Write-Host 'Leia LEIA-ME-USB-POSTO.txt'
