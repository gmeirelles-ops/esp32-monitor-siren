# Wrapper: garante Python do ESP-IDF no PATH antes do build.
$ErrorActionPreference = "Stop"
$idfPython = "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts"
if (-not (Test-Path "$idfPython\python.exe")) {
    throw "Python ESP-IDF nao encontrado: $idfPython\python.exe"
}
$env:PATH = "$idfPython;$env:PATH"
& (Join-Path $PSScriptRoot "..\sirene-validator\scripts\build_and_flash_windows.ps1") @args
exit $LASTEXITCODE
