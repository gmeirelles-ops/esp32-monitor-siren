#Requires -Version 5.1
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "windows_build_common.ps1")

$repoRoot = Get-RepoRoot
$appDir = Join-Path $repoRoot "sirene_manager_app"
$releaseDir = Join-Path $appDir "build\windows\x64\runner\Release"
$distRoot = Join-Path $repoRoot "dist"

$pubspecPath = Join-Path $appDir "pubspec.yaml"
$line = Get-Content $pubspecPath | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
if ($line -notmatch 'version:\s*([\d.]+)') { throw "version nao encontrada" }
$version = $Matches[1]

if (-not (Test-Path (Join-Path $releaseDir "sirene_manager_app.exe"))) {
    throw "Build nao encontrado. Execute: flutter build windows --release em sirene_manager_app"
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
$isccExe = Get-InnoSetupCompiler
Write-Host "==> Compilando instalador"
$compilerArgs = @(
    $issPath,
    "/DMyAppVersion=$version",
    "/DMyReleaseDir=$releaseDir",
    "/DMyOutputDir=$distRoot",
    "/DMyAppIcon=$iconPath",
    "/DMyReadmeFile=$readmeInstall"
)
$process = Start-Process -FilePath $isccExe -ArgumentList $compilerArgs -Wait -NoNewWindow -PassThru
if ($process.ExitCode -ne 0) { throw "Inno Setup falhou" }

Write-Host ""
Write-Host "ZIP:   $zipPath"
Write-Host "Setup: $setupPath"
