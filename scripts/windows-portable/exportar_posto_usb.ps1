#Requires -Version 5.1
<#
.SYNOPSIS
  Exporta catalogo e configuracao local para pasta dados_posto\ (pendrive).

.EXAMPLE
  cd F:\DipontoSireneValidator-1.0.1-win64
  powershell -ExecutionPolicy Bypass -File .\exportar_posto_usb.ps1
#>
param(
    [string]$PackageRoot = $PSScriptRoot,
    [string]$StationId,
    [switch]$SemSync,
    [switch]$Completo
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'posto_usb_paths.ps1')

$sqliteSrc = Get-SireneSqlitePath
$prefsSrc = Get-SirenePrefsPath
$destDir = Get-SireneUsbDadosDir -PackageRoot $PackageRoot
$prefs = $null

if (-not (Test-Path $sqliteSrc)) {
    throw "Banco local nao encontrado: $sqliteSrc`nAbra o app, baixe o catalogo da nuvem e tente de novo."
}

New-Item -ItemType Directory -Path $destDir -Force | Out-Null

Copy-Item $sqliteSrc (Join-Path $destDir 'sirene_app.sqlite') -Force
Write-Host "OK: sirene_app.sqlite ($((Get-Item $sqliteSrc).Length) bytes)"

if (Test-Path $prefsSrc) {
    $prefs = Get-Content $prefsSrc -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($Completo) {
        Write-Host 'OK: shared_preferences.json (cópia integral deste PC)'
    } else {
        if ($SemSync) {
            $prefs.'flutter.sync_enabled' = $false
            Write-Host 'Aviso: sync_enabled=false no pacote (posto sem login Firebase inicial).'
        }
        if ($StationId) {
            $prefs.'flutter.station_id' = $StationId
            Write-Host "station_id ajustado para: $StationId"
        }
        if ($prefs.PSObject.Properties.Name -contains 'flutter.printer_windows_name') {
            $prefs.'flutter.printer_windows_name' = ''
        }
        # Bancada e vinculo do posto sao locais (MQTT deste PC).
        if ($prefs.PSObject.Properties.Name -contains 'flutter.selected_device_id') {
            $prefs.PSObject.Properties.Remove('flutter.selected_device_id')
        }
        $prefs.'flutter.bancada_setup_complete' = $false
        Write-Host 'OK: bancada desvinculada no pacote (escolher de novo no posto)'
        Write-Host 'OK: shared_preferences.json (impressora USB zerada para o posto)'
    }
    $prefs | ConvertTo-Json -Compress | Set-Content (Join-Path $destDir 'shared_preferences.json') -Encoding UTF8
} else {
    Write-Host "Aviso: preferencias nao encontradas em $prefsSrc - so SQLite exportado."
}

$manifest = [ordered]@{
    exported_at  = (Get-Date).ToString('o')
    station_id   = if ($StationId) { $StationId } elseif ($prefs) { $prefs.'flutter.station_id' } else { $null }
    sqlite_bytes = (Get-Item (Join-Path $destDir 'sirene_app.sqlite')).Length
    sem_sync     = [bool]$SemSync
    config_completa = [bool]$Completo
    instrucoes   = if ($Completo) {
        'No posto: Instalar no PC.bat (restaura MQTT, catálogo e demais configs deste PC)'
    } else {
        'No posto: Instalar no PC.bat'
    }
}
$manifest | ConvertTo-Json | Set-Content (Join-Path $destDir 'manifest.json') -Encoding UTF8

Write-Host ''
Write-Host "Exportacao concluida em: $destDir" -ForegroundColor Green
Write-Host 'Leve o pendrive ao posto e rode Instalar no PC.bat'
