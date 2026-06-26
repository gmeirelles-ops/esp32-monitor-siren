# Gera tools/windows/esptool.exe via PyInstaller (Windows).
# Uso: powershell -ExecutionPolicy Bypass -File scripts\bundle_esptool_windows.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $Root "tools\windows"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

python -m pip install --upgrade esptool pyinstaller
python -m PyInstaller --onefile --name esptool (python -c "import esptool; import os; print(os.path.join(os.path.dirname(esptool.__file__), '__main__.py'))")

$Built = Join-Path $Root "dist\esptool.exe"
if (-not (Test-Path $Built)) {
    Write-Error "PyInstaller nao gerou dist\esptool.exe"
}
Copy-Item -Force $Built (Join-Path $OutDir "esptool.exe")
Write-Host "OK: $OutDir\esptool.exe"
