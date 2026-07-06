# Serve sirene-validator.bin e dispara OTA_UPDATE via MQTT (Windows).
# Uso:
#   .\scripts\bench_ota_windows.ps1 -Bancada 1
#   .\scripts\bench_ota_windows.ps1 -Bancada 1 -Broker mqtt.diponto.com -LanIp 192.168.51.28

param(
    [Parameter(Mandatory = $true)]
    [int]$Bancada,
    [string]$Site = "producao",
    [string]$Broker = "mqtt.diponto.com",
    [string]$LanIp = "",
    [int]$HttpPort = 8080,
    [string]$BinPath = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $BinPath) {
    $BinPath = Join-Path $Root "build\sirene-validator.bin"
}

if (-not (Test-Path $BinPath)) {
    Write-Error "Binario nao encontrado: $BinPath`nExecute o build antes."
}

if (-not $LanIp) {
    $LanIp = (
        Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*" -and
            $_.PrefixOrigin -ne "WellKnown"
        } |
        Select-Object -First 1 -ExpandProperty IPAddress
    )
}
if (-not $LanIp) {
    Write-Error "Nao foi possivel detectar IP LAN. Use -LanIp 192.168.x.x"
}

$ServeDir = Join-Path $env:TEMP "sirene_ota_$HttpPort"
New-Item -ItemType Directory -Force -Path $ServeDir | Out-Null
Copy-Item -Force $BinPath (Join-Path $ServeDir "sirene-validator.bin")

$OtaUrl = "http://${LanIp}:${HttpPort}/sirene-validator.bin"
$BancadaSlug = "bancada-{0:D2}" -f $Bancada
$Topic = "$Site/$BancadaSlug/comando"
$Payload = "{`"cmd`":`"OTA_UPDATE`",`"url`":`"$OtaUrl`"}"

Write-Host "=== Pre-check ===" -ForegroundColor Cyan
Write-Host "Binario : $BinPath ($((Get-Item $BinPath).Length) bytes)"
Write-Host "URL OTA : $OtaUrl"
Write-Host "Broker  : $Broker"
Write-Host "Topico  : $Topic"

# Teste local antes de subir servidor
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
    Write-Error "Python nao encontrado no PATH."
}

$serverJob = Start-Job -ScriptBlock {
    param($Dir, $Port)
    Set-Location $Dir
    python -m http.server $Port --bind 0.0.0.0
} -ArgumentList $ServeDir, $HttpPort

Start-Sleep -Seconds 2

try {
    $localOk = $false
    try {
        $r = Invoke-WebRequest -Uri "http://127.0.0.1:$HttpPort/sirene-validator.bin" -Method Head -TimeoutSec 5
        $localOk = ($r.StatusCode -eq 200)
    } catch {
        $localOk = $false
    }

    if (-not $localOk) {
        Write-Error @"
Servidor HTTP local nao respondeu em 127.0.0.1:$HttpPort
- Verifique se a porta esta livre
- Libere no Firewall Windows (rede privada): porta TCP $HttpPort
"@
    }
    Write-Host "HTTP local OK (200)" -ForegroundColor Green

    Write-Host ""
    Write-Host "IMPORTANTE: de outro dispositivo na mesma rede, abra:" -ForegroundColor Yellow
    Write-Host "  $OtaUrl"
    Write-Host "Se nao baixar o .bin, o ESP tambem falha com ESP_FAIL." -ForegroundColor Yellow
    Write-Host ""

    $pub = Get-Command mosquitto_pub -ErrorAction SilentlyContinue
    if (-not $pub) {
        Write-Warning "mosquitto_pub nao encontrado. Publique manualmente no MQTT Explorer:"
        Write-Host $Payload
    } else {
        Write-Host "Publicando OTA_UPDATE..." -ForegroundColor Cyan
        & mosquitto_pub -h $Broker -q 1 -t $Topic -m $Payload
    }

    Write-Host "Monitorando status/heartbeat por 120s (Ctrl+C para parar servidor)..." -ForegroundColor Cyan
    $sub = Get-Command mosquitto_sub -ErrorAction SilentlyContinue
    if ($sub) {
        & mosquitto_sub -h $Broker -v -t "$Site/$BancadaSlug/status" -t "$Site/$BancadaSlug/heartbeat"
    } else {
        Write-Host "Instale mosquitto-clients para monitorar, ou use MQTT Explorer."
        Start-Sleep -Seconds 120
    }
} finally {
    Stop-Job $serverJob -ErrorAction SilentlyContinue
    Remove-Job $serverJob -Force -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $ServeDir -ErrorAction SilentlyContinue
}
