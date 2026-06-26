#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$AppDir = Join-Path $Root "sirene_manager_app"

Push-Location $AppDir
try {
  flutter pub get
  flutter build windows --release
  Write-Host "Build OK: $AppDir\build\windows\x64\runner\Release\sirene_manager_app.exe"
} finally {
  Pop-Location
}
