# Serve sirene-validator.bin na LAN e publica OTA_UPDATE via MQTT (Windows).
#
# Uso:
#   .\scripts\ota_update_windows.ps1 -Bancada 1
#   .\scripts\ota_update_windows.ps1 -Bancada 3 -LanIp 192.168.51.50
#   .\scripts\ota_update_windows.ps1 -Bancada 1 -MqttUser devices -MqttPassword '***'
#   .\scripts\ota_update_windows.ps1 -Bancada 1 -ServeOnly
#
# Requisitos: Python 3 (PATH ou Espressif). paho-mqtt instalado automaticamente se faltar.

param(
    [Parameter(Mandatory = $true)]
    [int]$Bancada,
    [string]$Site = "producao",
    [string]$Broker = "mqtt.diponto.com",
    [int]$MqttPort = 443,
    [switch]$MqttTls,
    [string]$MqttUser = "devices",
    [string]$MqttPassword = "",
    [string]$LanIp = "",
    [int]$HttpPort = 8080,
    [string]$BinPath = "",
    [switch]$ServeOnly,
    [switch]$AllowFirewall,
    [int]$MonitorSeconds = 180
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir

function Test-VirtualInterfaceName {
    param([string]$Name)
    return $Name -match 'WSL|Hyper-V|vEthernet|VirtualBox|VMware|Docker|Npcap|Loopback'
}

function Get-OtaLanIPv4 {
    $candidates = @()
    Get-NetIPAddress -AddressFamily IPv4 | ForEach-Object {
        $ip = $_.IPAddress
        if ($ip -like "127.*" -or $ip -like "169.254.*") { return }
        if ($ip -eq "172.20.0.1" -or $ip -eq "172.17.0.1") { return }

        $adapter = Get-NetAdapter -InterfaceIndex $_.InterfaceIndex -ErrorAction SilentlyContinue
        $ifaceName = if ($adapter) { $adapter.Name } else { "" }
        if ($ifaceName -and (Test-VirtualInterfaceName $ifaceName)) { return }

        $priority = 3
        if ($ip -like "192.168.*") { $priority = 0 }
        elseif ($ip -like "10.*") { $priority = 1 }
        elseif ($ip -match "^172\.(1[6-9]|2[0-9]|3[0-1])\.") { $priority = 2 }

        $candidates += [pscustomobject]@{
            IP        = $ip
            Priority  = $priority
            Interface = $ifaceName
        }
    }
    if ($candidates.Count -eq 0) { return $null }
    return ($candidates | Sort-Object Priority, IP | Select-Object -First 1).IP
}

function Resolve-PythonExecutable {
    foreach ($cmd in @("python", "py", "python3")) {
        $found = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($found) {
            try {
                & $found.Source -c "import sys; sys.exit(0)" 2>$null
                if ($LASTEXITCODE -eq 0) { return $found.Source }
            } catch {}
        }
    }
    $espPy = "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
    if (Test-Path $espPy) { return $espPy }
    return $null
}

function Test-FirmwareHttp {
    param([string]$Url)
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        $out = & curl.exe -s -o NUL -w "%{http_code} %{size_download}" --max-time 8 $Url 2>$null
        if ($LASTEXITCODE -ne 0) { return $false }
        $parts = $out -split " "
        return ($parts[0] -eq "200" -and [int64]$parts[1] -gt 100000)
    }
    try {
        $r = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 8 -UseBasicParsing
        return ($r.StatusCode -eq 200 -and $r.RawContentLength -gt 100000)
    } catch {
        return $false
    }
}

function Ensure-PahoMqtt {
    param([string]$PythonExe)
    & $PythonExe -c "import paho.mqtt.publish" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Instalando paho-mqtt..." -ForegroundColor Yellow
        & $PythonExe -m pip install paho-mqtt -q
    }
}

function Publish-OtaMqtt {
    param(
        [string]$PythonExe,
        [string]$PublishScript,
        [int]$BancadaNum,
        [string]$SiteName,
        [string]$BrokerHost,
        [int]$Port,
        [bool]$UseTls,
        [string]$User,
        [string]$Password,
        [string]$OtaUrl
    )
    $args = @(
        $PublishScript,
        "--bancada", $BancadaNum,
        "--site", $SiteName,
        "--host", $BrokerHost,
        "--port", $Port,
        "--url", $OtaUrl
    )
    if ($User) {
        $args += @("--user", $User)
        $args += @("--password", $Password)
    }
    if ($UseTls) { $args += "--tls" }

    & $PythonExe @args
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao publicar MQTT (exit $LASTEXITCODE)"
    }
}

# --- Binário ---
if (-not $BinPath) {
    $releaseBin = Join-Path $Root "release\sirene-validator.bin"
    $buildBin = Join-Path $Root "build\sirene-validator.bin"
    if (Test-Path $releaseBin) { $BinPath = $releaseBin }
    elseif (Test-Path $buildBin) { $BinPath = $buildBin }
    else { $BinPath = $releaseBin }
}

if (-not (Test-Path $BinPath)) {
    Write-Error "Binario nao encontrado: $BinPath`nBuild: release\sirene-validator.bin ou build\sirene-validator.bin"
}

# --- IP LAN (ignora WSL) ---
if (-not $LanIp) {
    $LanIp = Get-OtaLanIPv4
}
if (-not $LanIp) {
    Write-Error "IP LAN nao detectado. Use -LanIp 192.168.x.x (nao use 172.20.0.1 do WSL)."
}

if ($LanIp -eq "172.20.0.1" -or $LanIp -eq "172.17.0.1") {
    Write-Error "IP $LanIp e de adaptador virtual. Use -LanIp com o Ethernet/Wi-Fi (ex.: 192.168.51.50)."
}

# --- MQTT TLS padrão para broker cloud ---
if (-not $PSBoundParameters.ContainsKey("MqttTls")) {
    $MqttTls = ($Broker -match "diponto\.com" -and $MqttPort -eq 443)
}

$Python = Resolve-PythonExecutable
if (-not $Python) {
    Write-Error "Python nao encontrado. Instale Python 3 ou ESP-IDF (Espressif)."
}

$ServeDir = Join-Path $env:TEMP "sirene_ota_$HttpPort"
New-Item -ItemType Directory -Force -Path $ServeDir | Out-Null
Copy-Item -Force $BinPath (Join-Path $ServeDir "sirene-validator.bin")

$OtaUrl = "http://${LanIp}:${HttpPort}/sirene-validator.bin"
$BancadaSlug = "bancada-{0:D2}" -f $Bancada
$Topic = "$Site/$BancadaSlug/comando"
$PayloadJson = "{`"cmd`":`"OTA_UPDATE`",`"url`":`"$OtaUrl`"}"

Write-Host ""
Write-Host "=== OTA LAN - sirene-validator ===" -ForegroundColor Cyan
$binSize = (Get-Item $BinPath).Length
Write-Host ('Binario  : {0} ({1} bytes)' -f $BinPath, $binSize)
Write-Host "IP LAN   : $LanIp"
Write-Host "URL OTA  : $OtaUrl"
Write-Host "Broker   : ${Broker}:$MqttPort $(if ($MqttTls) { '(TLS)' } else { '' })"
Write-Host "Topico   : $Topic"
Write-Host ""

if ($AllowFirewall) {
    try {
        $existing = Get-NetFirewallRule -DisplayName "Sirene OTA HTTP $HttpPort" -ErrorAction SilentlyContinue
        if (-not $existing) {
            New-NetFirewallRule -DisplayName "Sirene OTA HTTP $HttpPort" `
                -Direction Inbound -Protocol TCP -LocalPort $HttpPort `
                -Action Allow -Profile Private | Out-Null
            Write-Host "Firewall: regra criada (porta $HttpPort, rede privada)" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Firewall: execute como Administrador ou crie a regra manualmente (porta TCP $HttpPort)."
    }
}

$serverJob = Start-Job -ScriptBlock {
    param($Py, $Dir, $Port)
    & $Py -m http.server $Port --bind 0.0.0.0 --directory $Dir
} -ArgumentList $Python, $ServeDir, $HttpPort

Start-Sleep -Seconds 2

try {
    if (-not (Test-FirmwareHttp "http://127.0.0.1:$HttpPort/sirene-validator.bin")) {
        Write-Error "Servidor HTTP nao respondeu em 127.0.0.1:$HttpPort. Porta ocupada ou Python falhou."
    }
    Write-Host "HTTP localhost OK" -ForegroundColor Green

    if (-not (Test-FirmwareHttp $OtaUrl)) {
        Write-Warning "URL LAN nao respondeu: $OtaUrl. Libere firewall (-AllowFirewall como Admin) ou teste no celular."
    } else {
        Write-Host ('HTTP LAN OK: {0}' -f $OtaUrl) -ForegroundColor Green
    }

    Write-Host ""
    if (-not $ServeOnly) {
        $published = $false
        $mosquitto = Get-Command mosquitto_pub -ErrorAction SilentlyContinue
        if ($mosquitto -and -not $MqttTls) {
            Write-Host "Publicando OTA_UPDATE (mosquitto_pub)..." -ForegroundColor Cyan
            $pubArgs = @("-h", $Broker, "-p", "$MqttPort", "-q", "1", "-t", $Topic, "-m", $PayloadJson)
            if ($MqttUser) { $pubArgs = @("-u", $MqttUser) + $pubArgs }
            if ($MqttPassword) { $pubArgs = @("-P", $MqttPassword) + $pubArgs }
            & mosquitto_pub @pubArgs
            if ($LASTEXITCODE -eq 0) { $published = $true }
        }

        if (-not $published) {
            Write-Host "Publicando OTA_UPDATE (Python/paho-mqtt)..." -ForegroundColor Cyan
            Ensure-PahoMqtt -PythonExe $Python
            $publishScript = Join-Path $ScriptDir "publish_ota_once.py"
            Publish-OtaMqtt -PythonExe $Python -PublishScript $publishScript `
                -BancadaNum $Bancada -SiteName $Site -BrokerHost $Broker `
                -Port $MqttPort -UseTls:$MqttTls -User $MqttUser `
                -Password $MqttPassword -OtaUrl $OtaUrl
            $published = $true
        }

        if ($published) {
            Write-Host "MQTT publicado." -ForegroundColor Green
        }
    } else {
        Write-Host "Modo -ServeOnly: publique manualmente em $Topic" -ForegroundColor Yellow
        Write-Host $PayloadJson
    }

    Write-Host ""
    Write-Host ('Aguardando OTA ({0} s). Monitore:' -f $MonitorSeconds) -ForegroundColor Cyan
    Write-Host "  $Site/$BancadaSlug/status  (tipo:ota)"
    Write-Host "  $Site/$BancadaSlug/heartbeat  (firmware_version)"
    Write-Host "Ctrl+C para encerrar o servidor." -ForegroundColor DarkGray
    Write-Host ""

    $sub = Get-Command mosquitto_sub -ErrorAction SilentlyContinue
    if ($sub -and -not $MqttTls) {
        & mosquitto_sub -h $Broker -p $MqttPort -v `
            -t "$Site/$BancadaSlug/status" `
            -t "$Site/$BancadaSlug/heartbeat"
    } else {
        Start-Sleep -Seconds $MonitorSeconds
    }
} finally {
    Stop-Job $serverJob -ErrorAction SilentlyContinue
    Remove-Job $serverJob -Force -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $ServeDir -ErrorAction SilentlyContinue
    Write-Host "Servidor HTTP encerrado." -ForegroundColor DarkGray
}
