#Requires -Version 5.1
<#
.SYNOPSIS
  Compila sirene-validator (ESP-IDF) e grava apenas o app (0x20000) via USB.

.DESCRIPTION
  Se o repositorio estiver no OneDrive (caminho com acentos), sincroniza para
  C:\dev\sv_firmware_src antes de compilar (ESP-IDF nao tolera bem esse path).

.PARAMETER ComPort
  Porta serial (padrao COM11).

.PARAMETER SkipBuild
  Usa sirene-validator/release/sirene-validator.bin existente.

.PARAMETER SkipFlash
  Apenas compila e copia para release/.

.PARAMETER BuildRoot
  Diretorio ASCII para compilar (padrao C:\dev\sv_firmware_src).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File sirene-validator\scripts\build_and_flash_windows.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File sirene-validator\scripts\build_and_flash_windows.ps1 -ComPort COM3
#>
param(
    [string]$ComPort = "COM11",
    [switch]$SkipBuild,
    [switch]$SkipFlash,
    [string]$BuildRoot = "C:\dev\sv_firmware_src"
)

$ErrorActionPreference = "Stop"

$FwRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$RepoRoot = (Resolve-Path (Join-Path $FwRoot "..")).Path
$ReleaseBin = Join-Path $FwRoot "release\sirene-validator.bin"
$IdfExport = "C:\Espressif\frameworks\esp-idf-v5.5\export.ps1"
$FlashScript = Join-Path $RepoRoot "scripts\flash_usb_app.ps1"
$EsptoolBundle = Join-Path $RepoRoot "sirene_app\scripts\bundle_esptool_windows.ps1"

function Get-FirmwareVersion {
    param([string]$Root = $FwRoot)
    $header = Join-Path $Root "components\board_config\include\board_config.h"
    if (-not (Test-Path $header)) { return "?" }
    $m = Select-String -Path $header -Pattern '#define\s+FIRMWARE_VERSION\s+"([^"]+)"' |
        Select-Object -First 1
    if ($m) { return $m.Matches.Groups[1].Value }
    return "?"
}

function Sync-FirmwareTree {
    param(
        [string]$Source,
        [string]$Dest
    )
    if (-not (Test-Path $Dest)) {
        New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    }
    Write-Host "==> Sincronizando fonte para $Dest"
    & robocopy $Source $Dest /MIR /XD build .git .cache /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy falhou (exit $LASTEXITCODE)"
    }
}

function Resolve-CompileRoot {
    $gitTop = $null
    try {
        $gitTop = (git -C $FwRoot rev-parse --show-toplevel 2>$null).Trim()
    } catch {}
    $needsAscii = ($FwRoot -match 'OneDrive') -or ($gitTop -match 'OneDrive')
    if ($needsAscii -or $BuildRoot) {
        Sync-FirmwareTree -Source $FwRoot -Dest $BuildRoot
        return $BuildRoot
    }
    return $FwRoot
}

if (-not $SkipBuild) {
    if (-not (Test-Path $IdfExport)) {
        throw "ESP-IDF nao encontrado: $IdfExport`nInstale ESP-IDF 5.5 (Espressif Tools)."
    }

    $compileRoot = Resolve-CompileRoot
    $version = Get-FirmwareVersion -Root $compileRoot
    Write-Host "========================================"
    Write-Host " Build firmware $version"
    Write-Host " Fonte: $FwRoot"
    Write-Host " Build: $compileRoot"
    Write-Host "========================================"

    Push-Location $compileRoot
    try {
        . $IdfExport
        idf.py build
        if ($LASTEXITCODE -ne 0) { throw "idf.py build falhou (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }

    $builtBin = Join-Path $compileRoot "build\sirene-validator.bin"
    if (-not (Test-Path $builtBin)) {
        throw "Binario de build ausente: $builtBin"
    }

    New-Item -ItemType Directory -Force -Path (Split-Path $ReleaseBin) | Out-Null
    Copy-Item -Force $builtBin $ReleaseBin
    $hash = (Get-FileHash $ReleaseBin -Algorithm SHA256).Hash
    $size = (Get-Item $ReleaseBin).Length
    Write-Host "==> release: $ReleaseBin"
    Write-Host "    tamanho: $size bytes"
    Write-Host "    SHA256:  $hash"
}

if ($SkipFlash) {
    Write-Host "==> Flash ignorado (-SkipFlash)"
    exit 0
}

if (-not (Test-Path $ReleaseBin)) {
    throw "Binario nao encontrado: $ReleaseBin`nRode sem -SkipBuild ou compile antes."
}

$esptool = Join-Path $RepoRoot "sirene_app\tools\windows\esptool.exe"
if (-not (Test-Path $esptool)) {
    Write-Host "==> Gerando esptool.exe..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $EsptoolBundle
}

if (-not (Test-Path $FlashScript)) {
    throw "Script de flash ausente: $FlashScript"
}

Write-Host "========================================"
Write-Host " Gravando em $ComPort"
Write-Host "========================================"
& powershell -NoProfile -ExecutionPolicy Bypass -File $FlashScript -ComPort $ComPort -BinPath $ReleaseBin
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> Firmware gravado. Confira heartbeat: firmware_version = $(Get-FirmwareVersion)"
