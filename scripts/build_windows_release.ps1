#Requires -Version 5.1
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

Assert-WindowsBuildEnvironment

$DistRoot = Join-Path (Get-RepoRoot) "dist"
$TemplatesDir = Join-Path $PSScriptRoot "windows-portable"

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

$version = Get-SireneAppVersion
$packageName = "DipontoSireneValidator-$version-win64"
$packageDir = Join-Path $DistRoot $packageName
$zipPath = Join-Path $DistRoot "$packageName.zip"

Write-Host "==> Diponto Sirene Validator - build Windows $version"

Invoke-SireneFlutterWindowsBuild
$ReleaseDir = Get-SireneReleaseDir

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
