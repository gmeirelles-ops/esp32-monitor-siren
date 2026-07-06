#Requires -Version 5.1
# Build Windows release + ZIP em dist/ (sem depender de windows_build_common.ps1).
# Use se scripts\windows_build_common.ps1 estiver desatualizado ou com erro de encoding.
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$AppDir = Join-Path $Root "sirene_app"
$Release = Join-Path $AppDir "build\windows\x64\runner\Release"
$Dist = Join-Path $Root "dist"
$Templates = Join-Path $PSScriptRoot "windows-portable"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter nao encontrado no PATH."
}

$pubspec = Join-Path $AppDir "pubspec.yaml"
$versionLine = Get-Content $pubspec | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
if ($versionLine -notmatch 'version:\s*([\d.]+)') {
    throw "Nao foi possivel ler version de pubspec.yaml"
}
$version = $Matches[1]
$packageName = "DipontoSireneValidator-$version-win64"
$packageDir = Join-Path $Dist $packageName
$zipPath = Join-Path $Dist "$packageName.zip"

Write-Host "==> Diponto Sirene Validator - build Windows $version"
Write-Host "    Repo: $Root"

Push-Location $AppDir
try {
    Write-Host "==> flutter clean"
    flutter clean 2>&1 | ForEach-Object { Write-Host $_ }
    $buildWin = Join-Path $AppDir "build\windows"
    if (Test-Path $buildWin) {
        Remove-Item $buildWin -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "==> flutter pub get"
    flutter pub get 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get falhou" }

    Write-Host "==> dart run build_runner build"
    dart run build_runner build 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw "build_runner falhou" }

    Write-Host "==> flutter build windows --release"
    flutter build windows --release 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows falhou" }
}
finally {
    Pop-Location
}

if (-not (Test-Path (Join-Path $Release "sirene_app.exe"))) {
    throw "Build nao encontrado: $Release\sirene_app.exe"
}

New-Item -ItemType Directory -Path $Dist -Force | Out-Null
if (Test-Path $packageDir) {
    Remove-Item $packageDir -Recurse -Force
}
$appDest = Join-Path $packageDir "app"
New-Item -ItemType Directory -Path $appDest -Force | Out-Null

Write-Host "==> Copiando para dist\$packageName\app"
Copy-Item -Path (Join-Path $Release "*") -Destination $appDest -Recurse -Force

$toolsSrc = Join-Path $AppDir "tools\windows"
if (Test-Path $toolsSrc) {
    $toolsDest = Join-Path $appDest "tools\windows"
    New-Item -ItemType Directory -Path $toolsDest -Force | Out-Null
    Copy-Item -Path (Join-Path $toolsSrc "*") -Destination $toolsDest -Recurse -Force
}

$readmeTemplate = Get-Content (Join-Path $Templates "LEIA-ME.txt") -Raw -Encoding UTF8
$readmeTemplate.Replace("{{VERSION}}", $version) | Set-Content (Join-Path $packageDir "LEIA-ME.txt") -Encoding UTF8
Copy-Item (Join-Path $Templates "Iniciar Diponto Sirene Validator.bat") $packageDir -Force

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Write-Host "==> Gerando ZIP"
Compress-Archive -Path $packageDir -DestinationPath $zipPath -Force

Write-Host ""
Write-Host "Pronto!"
Write-Host "  Pasta: $packageDir"
Write-Host "  ZIP:   $zipPath"
