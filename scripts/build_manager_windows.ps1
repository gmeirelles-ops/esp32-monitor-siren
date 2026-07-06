#Requires -Version 5.1
<#
.SYNOPSIS
  Build release Windows do sirene_manager_app + ZIP e instalador em dist/.
#>
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

Assert-WindowsBuildEnvironment

$repoRoot = Get-RepoRoot
$appDir = Join-Path $repoRoot "sirene_manager_app"
$releaseDir = Join-Path $appDir "build\windows\x64\runner\Release"
$distRoot = Join-Path $repoRoot "dist"

function Get-ManagerAppVersion {
    $pubspecPath = Join-Path $appDir "pubspec.yaml"
    $line = Get-Content $pubspecPath | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
    if ($line -match 'version:\s*([\d.]+)') {
        return $Matches[1]
    }
    throw "Nao foi possivel ler version de sirene_manager_app/pubspec.yaml"
}

$version = Get-ManagerAppVersion
Write-Host "==> Diponto Sirene Gestor - build Windows $version"
Write-Host "    App: $appDir"

Push-Location $appDir
try {
    Write-Host "==> flutter clean"
    flutter clean 2>&1 | ForEach-Object { Write-Host $_ }
    $buildWin = Join-Path $appDir "build\windows"
    if (Test-Path $buildWin) {
        Remove-Item $buildWin -Recurse -Force -ErrorAction SilentlyContinue
    }
    Invoke-ExternalBuildStep "flutter pub get" { flutter pub get } "flutter pub get falhou"
    Invoke-ExternalBuildStep "flutter build windows --release" { flutter build windows --release } "flutter build windows falhou"
}
finally {
    Pop-Location
}

if (-not (Test-Path $releaseDir)) {
    throw "Saida de build nao encontrada: $releaseDir"
}

$packageName = "DipontoSireneGestor-$version-win64"
$packageDir = Join-Path $distRoot $packageName
$zipPath = Join-Path $distRoot "$packageName.zip"

New-Item -ItemType Directory -Path $distRoot -Force | Out-Null
if (Test-Path $packageDir) { Remove-Item $packageDir -Recurse -Force }
$appDest = Join-Path $packageDir "app"
New-Item -ItemType Directory -Path $appDest -Force | Out-Null

Write-Host "==> Copiando Release para dist/$packageName/app"
Copy-Item -Path (Join-Path $releaseDir "*") -Destination $appDest -Recurse -Force

$readme = @(
    "Diponto Sirene Gestor v$version (portatil)",
    "",
    "Execute: app\sirene_manager_app.exe",
    "Login Firebase necessario. Postos devem ter sync ativo.",
    "",
    "Relatorios: Documentos\relatorios_gestor"
) -join "`r`n"
$readme | Set-Content (Join-Path $packageDir "LEIA-ME.txt") -Encoding UTF8

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Write-Host "==> Gerando ZIP"
Compress-Archive -Path $packageDir -DestinationPath $zipPath -Force

$issPath = Join-Path $PSScriptRoot "windows-installer\DipontoSireneManager.iss"
$iconPath = Join-Path $repoRoot "sirene_app\windows\runner\resources\app_icon.ico"
$readmeInstall = Join-Path $PSScriptRoot "windows-installer\LEIA-ME.manager.install.txt"
$readmeContent = (Get-Content $readmeInstall -Raw -Encoding UTF8).Replace("{{VERSION}}", $version)
$readmeContent | Set-Content $readmeInstall -Encoding UTF8

$setupPath = Join-Path $distRoot "DipontoSireneGestor-$version-setup.exe"
if (Test-Path $issPath) {
  $isccExe = Get-InnoSetupCompiler
  Write-Host "==> Compilando instalador com Inno Setup"
  $compilerArgs = @(
      $issPath,
      "/DMyAppVersion=$version",
      "/DMyReleaseDir=$releaseDir",
      "/DMyOutputDir=$distRoot",
      "/DMyAppIcon=$iconPath",
      "/DMyReadmeFile=$readmeInstall"
  )
  $process = Start-Process -FilePath $isccExe -ArgumentList $compilerArgs -Wait -NoNewWindow -PassThru
  if ($process.ExitCode -ne 0) {
      throw "Compilacao Inno Setup falhou (exit $($process.ExitCode))"
  }
}

Write-Host ""
Write-Host "Pronto!"
Write-Host "  ZIP:        $zipPath"
if (Test-Path $setupPath) {
    Write-Host "  Instalador: $setupPath"
}
