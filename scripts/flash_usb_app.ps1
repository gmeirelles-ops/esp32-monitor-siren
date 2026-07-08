# Grava apenas o app (offset 0x20000) via USB — usa --no-stub (compatível com esptool empacotado).
param(
    [string]$ComPort = "COM11",
    [string]$BinPath = (Join-Path $PSScriptRoot "..\sirene-validator\release\sirene-validator.bin")
)

$ErrorActionPreference = "Stop"

function Resolve-Esptool {
    $bundled = Join-Path $PSScriptRoot "..\sirene_app\tools\windows\esptool.exe"
    if (Test-Path $bundled) { return @{ exe = $bundled; prefix = @() } }

    $espPy = "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
    if (Test-Path $espPy) { return @{ exe = $espPy; prefix = @("-m", "esptool") } }

    throw "esptool nao encontrado. Rode sirene_app\scripts\bundle_esptool_windows.ps1"
}

if (-not (Test-Path $BinPath)) {
    throw "Binario nao encontrado: $BinPath"
}

$tool = Resolve-Esptool
$args = @(
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
    "0x20000",
    $BinPath
) | Where-Object { $_ -ne "" }

Write-Host "==> Gravando $BinPath em $ComPort"
& $tool.exe @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "==> OK"
