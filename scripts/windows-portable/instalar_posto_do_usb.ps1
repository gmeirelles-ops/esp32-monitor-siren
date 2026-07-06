#Requires -Version 5.1
<#
.SYNOPSIS
  Instala app portátil + dados do pendrive no PC do posto (sem baixar catálogo da nuvem).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File instalar_posto_do_usb.ps1
#>
param(
    [string]$PackageRoot = $PSScriptRoot,
    [string]$InstallDir = 'C:\Diponto\SireneValidator',
    [switch]$SoDados
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'posto_usb_paths.ps1')

$appSrc = Join-Path $PackageRoot 'app'
$dadosDir = Get-SireneUsbDadosDir -PackageRoot $PackageRoot
$sqliteSrc = Join-Path $dadosDir 'sirene_app.sqlite'
$prefsSrc = Join-Path $dadosDir 'shared_preferences.json'

if (-not (Test-Path $sqliteSrc)) {
    throw "Pacote sem dados_posto\sirene_app.sqlite. Exporte no PC de configuração com exportar_posto_usb.ps1"
}

# Fechar app se estiver aberto
Get-Process sirene_app -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

if (-not $SoDados) {
    if (-not (Test-Path (Join-Path $appSrc 'sirene_app.exe'))) {
        throw "Pasta app\ incompleta no pendrive. Use o ZIP win64 inteiro."
    }
    Write-Host "==> Copiando programa para $InstallDir"
    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -Path (Join-Path $appSrc '*') -Destination $InstallDir -Recurse -Force
    Get-ChildItem -LiteralPath $InstallDir -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

    $desktop = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktop 'Diponto Sirene Validator.lnk'
    $wsh = New-Object -ComObject WScript.Shell
    $sc = $wsh.CreateShortcut($shortcutPath)
    $sc.TargetPath = Join-Path $InstallDir 'sirene_app.exe'
    $sc.WorkingDirectory = $InstallDir
    $sc.Description = 'Diponto Sirene Validator'
    $sc.Save()
    Write-Host "Atalho na área de trabalho criado."
}

Write-Host '==> Restaurando catálogo e configuração'
$sqliteDest = Get-SireneSqlitePath
$prefsDestDir = Get-SirenePrefsDir
$prefsDest = Get-SirenePrefsPath

New-Item -ItemType Directory -Path (Split-Path $sqliteDest -Parent) -Force | Out-Null
Copy-Item $sqliteSrc $sqliteDest -Force
Write-Host "OK: $sqliteDest"

if (Test-Path $prefsSrc) {
    New-Item -ItemType Directory -Path $prefsDestDir -Force | Out-Null
    Copy-Item $prefsSrc $prefsDest -Force
    Write-Host "OK: $prefsDest"
}

if (Test-Path (Join-Path $dadosDir 'manifest.json')) {
    Write-Host ''
    Get-Content (Join-Path $dadosDir 'manifest.json') -Raw | Write-Host
}

Write-Host ''
Write-Host 'Instalação concluída.' -ForegroundColor Green
if (-not $SoDados) {
    Write-Host "Abra: $InstallDir\sirene_app.exe"
    Write-Host 'Ou o atalho na área de trabalho.'
}
Write-Host 'Login: selecione operador + PIN (já vêm no catálogo exportado).'
Write-Host 'Ajuste impressora USB em Configurações se necessário.'
Write-Host 'Sync nuvem: se exportou com -SemSync, habilite depois em Configurações (login Firebase).'
