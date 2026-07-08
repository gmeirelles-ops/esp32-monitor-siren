# Gera tools/windows/esptool.exe via PyInstaller (Windows).
# Uso: powershell -ExecutionPolicy Bypass -File scripts\bundle_esptool_windows.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $Root "tools\windows"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Resolve-PythonForEsptool {
    foreach ($cmd in @("python", "py", "python3")) {
        $found = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($found) {
            try {
                & $found.Source -c "import sys; sys.exit(0)" 2>$null
                if ($LASTEXITCODE -eq 0) { return $found.Source }
            } catch {}
        }
    }
    $espPy = "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
    if (Test-Path $espPy) { return $espPy }
    throw "Python nao encontrado. Instale Python 3 ou ESP-IDF (Espressif)."
}

$Python = Resolve-PythonForEsptool
Write-Host "Python: $Python"

& $Python -m pip install --upgrade pyinstaller -q
$bundleEsptool = & $Python -m pip show esptool 2>$null
if ($bundleEsptool) {
    Write-Host "Usando esptool ja instalado no ambiente IDF"
} else {
    & $Python -m pip install "esptool~=4.12.dev2" -q
}
$mainPy = & $Python -c "import esptool, os; print(os.path.join(os.path.dirname(esptool.__file__), '__main__.py'))"
Push-Location $Root
try {
    & $Python -m PyInstaller --onefile --name esptool --clean --collect-data esptool $mainPy
}
finally {
    Pop-Location
}

$Built = Join-Path $Root "dist\esptool.exe"
if (-not (Test-Path $Built)) {
    Write-Error "PyInstaller nao gerou dist\esptool.exe"
}
Copy-Item -Force $Built (Join-Path $OutDir "esptool.exe")
$mb = [math]::Round((Get-Item (Join-Path $OutDir "esptool.exe")).Length / 1MB, 1)
Write-Host "OK: $OutDir\esptool.exe ($mb MB)"
