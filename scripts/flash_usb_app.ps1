# Grava firmware nas duas particoes OTA + otadata via USB.
# Offsets lidos do build ESP-IDF (flasher_args.json + partition-table.bin).
param(
    [string]$ComPort = "COM11",
    [string]$BinPath = "",
    [string]$BuildDir = "C:\dev\sv_firmware_src\build"
)

$ErrorActionPreference = "Stop"

function Resolve-Esptool {
    $bundled = Join-Path $PSScriptRoot "..\sirene_app\tools\windows\esptool.exe"
    if (Test-Path $bundled) { return @{ exe = $bundled; prefix = @() } }

    $espPy = "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
    if (Test-Path $espPy) { return @{ exe = $espPy; prefix = @("-m", "esptool") } }

    throw "esptool nao encontrado. Rode sirene_app\scripts\bundle_esptool_windows.ps1"
}

function Get-OtaPartitionOffsets {
    param([string]$BuildRoot)

    $ptBin = Join-Path $BuildRoot "partition_table\partition-table.bin"
    if (-not (Test-Path $ptBin)) {
        throw "Partition table ausente: $ptBin`nRode idf.py build antes."
    }

    $py = "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
    $gen = "C:\Espressif\frameworks\esp-idf-v5.5\components\partition_table\gen_esp32part.py"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & $py $gen $ptBin 2>&1 | Out-String
    } finally {
        $ErrorActionPreference = $prevEap
    }
    if (-not $out) { throw "gen_esp32part retornou vazio para $ptBin" }

    $ota0 = $null
    $ota1 = $null
    foreach ($line in ($out -split "`r?`n")) {
        if ($line -match 'ota_0,\s*app,\s*ota_0,\s*(0x[0-9A-Fa-f]+)') { $ota0 = $Matches[1] }
        if ($line -match 'ota_1,\s*app,\s*ota_1,\s*(0x[0-9A-Fa-f]+)') { $ota1 = $Matches[1] }
    }
    if (-not $ota0 -or -not $ota1) {
        throw "Offsets ota_0/ota_1 nao encontrados em partition-table.bin"
    }

    $flasherArgs = Join-Path $BuildRoot "flasher_args.json"
    if (-not (Test-Path $flasherArgs)) {
        throw "flasher_args.json ausente: $flasherArgs"
    }
    $fa = Get-Content $flasherArgs -Raw | ConvertFrom-Json
    $otaDataOffset = $null
    $otaDataFile = $null
    if ($fa.flash_files.PSObject.Properties.Name -contains '0xf000') {
        $otaDataOffset = '0xf000'
        $otaDataFile = Join-Path $BuildRoot ($fa.flash_files.'0xf000')
    } else {
        foreach ($prop in $fa.flash_files.PSObject.Properties) {
            if ($prop.Value -like '*ota_data*') {
                $otaDataOffset = $prop.Name
                $otaDataFile = Join-Path $BuildRoot $prop.Value
                break
            }
        }
    }
    if (-not $otaDataOffset) {
        $otaDataOffset = '0x7000'
        $otaDataFile = Join-Path $BuildRoot "ota_data_initial.bin"
    }

    return @{
        Ota0 = $ota0
        Ota1 = $ota1
        OtaData = $otaDataOffset
        OtaDataFile = $otaDataFile
    }
}

function Test-BinFirmwareVersion {
    param([string]$Path, [string]$Expected)
    $text = [System.Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($Path))
    return $text.Contains($Expected)
}

if (-not $BinPath) {
    $candidates = @(
        (Join-Path $BuildDir "sirene-validator.bin"),
        (Join-Path $PSScriptRoot "..\sirene-validator\release\sirene-validator.bin")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $BinPath = $c; break }
    }
}

if (-not $BinPath -or -not (Test-Path $BinPath)) {
    throw "Binario nao encontrado. Compile com idf.py build."
}

$offsets = Get-OtaPartitionOffsets -BuildRoot $BuildDir
$tool = Resolve-Esptool

Write-Host "==> Flash USB $ComPort"
Write-Host "    bin: $BinPath"
Write-Host "    ota_0: $($offsets.Ota0)"
Write-Host "    ota_1: $($offsets.Ota1)"
Write-Host "    otadata: $($offsets.OtaData)"

    $version = '1.8.8'
    $header = Join-Path $PSScriptRoot "..\sirene-validator\components\board_config\include\board_config.h"
    if (Test-Path $header) {
        $m = Select-String -Path $header -Pattern '#define\s+FIRMWARE_VERSION\s+"([^"]+)"' | Select-Object -First 1
        if ($m) { $version = $m.Matches.Groups[1].Value }
    }
    if (-not (Test-BinFirmwareVersion -Path $BinPath -Expected $version)) {
        Write-Warning "AVISO: binario nao contem string $version - rode rebuild antes de confiar no heartbeat."
    }

$flashArgs = @(
    $tool.prefix
    "--chip", "esp32",
    "--port", $ComPort,
    "--baud", "460800",
    "--before", "default_reset",
    "--after", "hard_reset",
    "--no-stub",
    "write_flash",
    "--flash_mode", "dio",
    "--flash_freq", "40m",
    "--flash_size", "4MB",
    $offsets.Ota0, $BinPath,
    $offsets.Ota1, $BinPath
)

if ((Test-Path $offsets.OtaDataFile)) {
    $flashArgs += @($offsets.OtaData, $offsets.OtaDataFile)
    Write-Host "    otadata file: $($offsets.OtaDataFile)"
} else {
    Write-Warning "otadata_initial.bin ausente - gravando so ota_0 + ota_1"
}

$flashArgs = $flashArgs | Where-Object { $_ -ne "" }

& $tool.exe @flashArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "==> OK - confira heartbeat: firmware_version e uptime baixo"
