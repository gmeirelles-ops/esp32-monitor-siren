#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$AppDir = Join-Path $RepoRoot "sirene_app"
$DistRoot = Join-Path $RepoRoot "dist"
$TemplatesDir = Join-Path $PSScriptRoot "windows-portable"
$ReleaseDir = Join-Path $AppDir "build\windows\x64\runner\Release"

function Get-AppVersion {
    $pubspecPath = Join-Path $AppDir "pubspec.yaml"
    $line = Get-Content $pubspecPath | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
    if ($line -match 'version:\s*([\d.]+)') {
        return $Matches[1]
    }
    throw "Nao foi possivel ler version de pubspec.yaml"
}

function Test-PackageLayout {
    param([string]$PackageDir)

    $exe = Join-Path $PackageDir "app\sirene_app.exe"
    $data = Join-Path $PackageDir "app\data"
    $readme = Join-Path $PackageDir "LEIA-ME.txt"
    $launcher = Join-Path $PackageDir "Iniciar Diponto Sirene Validator.bat"

    foreach ($path in @($exe, $data, $readme, $launcher)) {
        if (-not (Test-Path $path)) {
            throw "Pacote incompleto: ausente $path"
        }
    }
}

if ($PSVersionTable.PSPlatform -and $PSVersionTable.PSPlatform -ne "Win32NT") {
    throw "Este script deve ser executado no Windows. Use GitHub Actions (workflow_dispatch) ou uma maquina Windows."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter nao encontrado no PATH. Instale o Flutter SDK e o workload C++ do Visual Studio."
}

$version = Get-AppVersion
$packageName = "DipontoSireneValidator-$version-win64"
$packageDir = Join-Path $DistRoot $packageName
$zipPath = Join-Path $DistRoot "$packageName.zip"

Write-Host "==> Diponto Sirene Validator — build Windows $version"

Push-Location $AppDir
try {
    Write-Host "==> flutter pub get"
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get falhou" }

    Write-Host "==> dart run build_runner build"
    dart run build_runner build --delete-conflicting-outputs
    if ($LASTEXITCODE -ne 0) { throw "build_runner falhou" }

    Write-Host "==> flutter build windows --release"
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows falhou" }
}
finally {
    Pop-Location
}

if (-not (Test-Path $ReleaseDir)) {
    throw "Saida de build nao encontrada: $ReleaseDir"
}

if (Test-Path $packageDir) {
    Remove-Item $packageDir -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $packageDir "app") -Force | Out-Null

Write-Host "==> Copiando Release para pacote portatil"
Copy-Item -Path (Join-Path $ReleaseDir "*") -Destination (Join-Path $packageDir "app") -Recurse -Force

$readmeTemplate = Get-Content (Join-Path $TemplatesDir "LEIA-ME.txt") -Raw -Encoding UTF8
$readmeTemplate.Replace("{{VERSION}}", $version) | Set-Content (Join-Path $packageDir "LEIA-ME.txt") -Encoding UTF8

Copy-Item (Join-Path $TemplatesDir "Iniciar Diponto Sirene Validator.bat") $packageDir -Force

Write-Host "==> Verificando estrutura do pacote"
Test-PackageLayout -PackageDir $packageDir

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Write-Host "==> Gerando ZIP"
Compress-Archive -Path $packageDir -DestinationPath $zipPath -Force

Write-Host ""
Write-Host "Pronto!"
Write-Host "  Pasta: $packageDir"
Write-Host "  ZIP:   $zipPath"
Write-Host "Copie o ZIP para o pendrive, extraia no PC do posto e execute o arquivo .bat"
