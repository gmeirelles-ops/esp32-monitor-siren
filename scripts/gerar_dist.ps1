#Requires -Version 5.1
<#
.SYNOPSIS
  Gera dist/ do Diponto Sirene Validator (instalador setup.exe; ZIP opcional).

.DESCRIPTION
  Script unico para empacotar o app quando quiser levar para outro PC.
  GERAR-DIST.bat chama com -ApenasInstalador (so setup.exe).
  Use -ComZip para incluir tambem o pacote portatil ZIP.

.PARAMETER ApenasEmpacotar
  Nao recompila. Usa sirene_app\build\windows\x64\runner\Release\ existente.

.PARAMETER ApenasInstalador
  Gera apenas o setup.exe (sem pasta portatil nem ZIP). Padrao do GERAR-DIST.bat.

.PARAMETER ComZip
  Gera tambem o pacote portatil ZIP (alem do instalador, se aplicavel).

.PARAMETER SemInstalador
  Gera apenas o ZIP portatil (sem setup.exe).

.PARAMETER Incremental
  Build sem flutter clean (mais rapido; use se o ultimo build ainda e valido).

.PARAMETER SdkZip
  Caminho para firebase_cpp_sdk_windows_12.7.0.zip (evita download da internet).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\gerar_dist.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\gerar_dist.ps1 -Incremental

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\gerar_dist.ps1 -ApenasEmpacotar

.EXAMPLE
  Duplo clique em GERAR-DIST.bat na raiz do repositorio.
#>
param(
    [switch]$ApenasEmpacotar,
    [switch]$ApenasInstalador,
    [switch]$ComZip,
    [switch]$SemInstalador,
    [switch]$Incremental,
    [switch]$ComConfigDestePc,
    [switch]$ConfigCompleta,
    [string]$SdkZip
)

$ErrorActionPreference = "Stop"

if ($ApenasInstalador -and $SemInstalador) {
    throw "Use apenas um de: -ApenasInstalador ou -SemInstalador"
}
if ($ApenasInstalador -and $ComConfigDestePc) {
    throw "-ComConfigDestePc exige ZIP portatil; use -ComZip em vez de -ApenasInstalador"
}

# Padrao historico (sem flags): ZIP + instalador. GERAR-DIST.bat passa -ApenasInstalador.
$gerarZip = $ComZip -or ((-not $ApenasInstalador) -and (-not $SemInstalador))
$gerarSetup = (-not $SemInstalador)

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

function Write-DistReadme {
    param(
        [string]$Version,
        [string]$DistRoot,
        [switch]$SemInstalador,
        [switch]$ComConfigDestePc,
        [switch]$ApenasInstalador
    )

    $readme = Join-Path $DistRoot "LEIA-ME-INSTALACAO.txt"
    $lines = @(
        "Diponto Sirene Validator - instalar em outro PC",
        "================================================",
        "",
        "Versao: $Version",
        "Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
        "",
        "ARQUIVOS",
        "--------"
    )

    if ($ApenasInstalador) {
        $lines += @(
            "  Instalador: DipontoSireneValidator-$Version-setup.exe",
            "",
            "PASSO A PASSO - INSTALADOR",
            "-------------------------",
            "1. Copie DipontoSireneValidator-$Version-setup.exe para o PC do posto.",
            "2. Duplo clique no setup.exe.",
            "3. Se o Windows avisar: Mais informacoes > Executar assim mesmo.",
            "4. Abra pelo menu Iniciar.",
            ""
        )
    }
    elseif (-not $SemInstalador) {
        $lines += @(
            "  Instalador (recomendado): DipontoSireneValidator-$Version-setup.exe",
            "  Portatil (ZIP):           DipontoSireneValidator-$Version-win64.zip",
            "",
            "PASSO A PASSO - INSTALADOR",
            "-------------------------",
            "1. Copie DipontoSireneValidator-$Version-setup.exe para o PC do posto.",
            "2. Duplo clique no setup.exe.",
            "3. Se o Windows avisar: Mais informacoes > Executar assim mesmo.",
            "4. Abra pelo menu Iniciar.",
            ""
        )
    }
    else {
        $lines += @(
            "  Portatil (ZIP): DipontoSireneValidator-$Version-win64.zip",
            "",
            "PASSO A PASSO - PORTATIL",
            "------------------------",
            "1. Extraia o ZIP em uma pasta (ex.: C:\DipontoSirene).",
            "2. Execute: Iniciar Diponto Sirene Validator.bat",
            ""
        )
    }

    $lines += @(
        "DADOS E FIREBASE",
        "----------------"
    )
    if ($ComConfigDestePc) {
        $lines += @(
            "- Este pacote inclui dados_posto\ exportados DESTE PC (MQTT, catálogo, operadores).",
            "- No posto: use o ZIP e rode Instalar no PC.bat (recomendado).",
            "- O setup.exe instala só o programa; depois copie dados_posto\ manualmente ou use o ZIP.",
            ""
        )
    } else {
        $lines += @(
            "- Login Firebase no app > Configuracoes > Baixar catalogo da nuvem.",
            "- Para copiar dados deste PC: Exportar dados para USB.bat no pendrive.",
            ""
        )
    }
    $lines += @(
        "GERAR DIST NOVAMENTE",
        "--------------------",
        "Na maquina de desenvolvimento:",
        "  powershell -ExecutionPolicy Bypass -File scripts\gerar_dist.ps1 -ApenasInstalador",
        "Ou duplo clique em GERAR-DIST.bat"
    )

    $lines | Set-Content $readme -Encoding UTF8
}

Assert-WindowsBuildEnvironment

$repoRoot = Get-RepoRoot
$distRoot = Join-Path $repoRoot "dist"
$version = Get-SireneAppVersion
$packageName = "DipontoSireneValidator-$version-win64"
$zipPath = Join-Path $distRoot "$packageName.zip"
$setupPath = Join-Path $distRoot "DipontoSireneValidator-$version-setup.exe"
$releaseExe = Join-Path (Get-SireneReleaseDir) "sirene_app.exe"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Diponto Sirene Validator - gerar dist" -ForegroundColor Cyan
Write-Host " Versao: $version" -ForegroundColor Cyan
if ($ApenasInstalador) {
    Write-Host " Modo:   apenas instalador (setup.exe)" -ForegroundColor Cyan
} elseif ($SemInstalador) {
    Write-Host " Modo:   apenas ZIP portatil" -ForegroundColor Cyan
} elseif ($ComZip) {
    Write-Host " Modo:   instalador + ZIP" -ForegroundColor Cyan
} else {
    Write-Host " Modo:   instalador + ZIP (padrao script)" -ForegroundColor Cyan
}
Write-Host " Repo:   $repoRoot" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($ApenasEmpacotar) {
    if (-not (Test-Path $releaseExe)) {
        throw @"
Build Release nao encontrado:
  $releaseExe

Rode sem -ApenasEmpacotar para compilar primeiro, ou execute:
  flutter build windows --release
"@
    }
    Write-Host "==> Modo: apenas empacotar (sem recompilar)" -ForegroundColor Yellow
}
elseif ($Incremental) {
    Write-Host "==> Modo: build incremental (sem flutter clean)" -ForegroundColor Yellow
}
else {
    Write-Host "==> Modo: build completo (flutter clean + release)" -ForegroundColor Yellow
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()

try {
    if (-not $ApenasEmpacotar) {
        Invoke-SireneFlutterWindowsBuild -SkipClean:$Incremental -FirebaseSdkZip $SdkZip
    }

    if ($gerarZip) {
        Write-Host ""
        Write-Host "==> Empacotando ZIP portatil"
        $pkg = Invoke-SirenePortablePackage -SkipZip:$ComConfigDestePc

        if ($ComConfigDestePc) {
            Write-Host ""
            Write-Host "==> Exportando configuracao e catalogo deste PC para dados_posto\"
            $exportScript = Join-Path $PSScriptRoot "windows-portable\exportar_posto_usb.ps1"
            $exportArgs = @{
                PackageRoot = $pkg.PackageDir
            }
            if ($ConfigCompleta) { $exportArgs['Completo'] = $true }
            & $exportScript @exportArgs

            $zipPath = Join-Path $distRoot "$packageName.zip"
            if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
            Write-Host "==> Gerando ZIP (com dados_posto\)"
            Compress-Archive -Path $pkg.PackageDir -DestinationPath $zipPath -Force
            $pkg = [PSCustomObject]@{
                Version    = $version
                PackageDir = $pkg.PackageDir
                ZipPath    = $zipPath
            }
        }
    } else {
        $pkg = $null
    }

    if ($gerarSetup) {
        Write-Host ""
        Write-Host "==> Gerando instalador setup.exe"
        $setupPath = Compile-SireneWindowsInstaller -Version $version
    }

    Write-DistReadme -Version $version -DistRoot $distRoot -SemInstalador:(-not $gerarSetup) `
        -ComConfigDestePc:$ComConfigDestePc -ApenasInstalador:$ApenasInstalador
}
catch {
    Write-Host ""
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$sw.Stop()

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Pronto em $([math]::Round($sw.Elapsed.TotalMinutes, 1)) min" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Artefatos em dist\:" -ForegroundColor Green

if ($pkg -and (Test-Path $pkg.PackageDir)) {
    Write-Host "  Pasta:  $packageName\"
}
if ($gerarZip -and (Test-Path $zipPath)) {
    $mb = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
    Write-Host "  ZIP:    $packageName.zip ($mb MB)"
}
if ($gerarSetup -and (Test-Path $setupPath)) {
    $mb = [math]::Round((Get-Item $setupPath).Length / 1MB, 1)
    Write-Host "  Setup:  DipontoSireneValidator-$version-setup.exe ($mb MB)"
}

Write-Host ""
if ($gerarSetup) {
    Write-Host "Para o posto: copie o setup.exe." -ForegroundColor Cyan
}
if ($gerarZip) {
    Write-Host "ZIP portatil disponivel em dist\ (scripts USB na pasta)." -ForegroundColor Cyan
}
Write-Host ""
