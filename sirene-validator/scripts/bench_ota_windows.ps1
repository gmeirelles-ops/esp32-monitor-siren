# Encaminha para ota_update_windows.ps1 (IP LAN correto, release/, MQTT TLS).
# Uso: .\scripts\bench_ota_windows.ps1 -Bancada 1

param(
    [Parameter(Mandatory = $true)]
    [int]$Bancada,
    [string]$Site = "producao",
    [string]$Broker = "mqtt.diponto.com",
    [string]$LanIp = "",
    [int]$HttpPort = 8080,
    [string]$BinPath = "",
    [string]$MqttUser = "devices",
    [string]$MqttPassword = "",
    [switch]$AllowFirewall
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ota = Join-Path $ScriptDir "ota_update_windows.ps1"

$forward = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", $ota,
    "-Bancada", $Bancada,
    "-Site", $Site,
    "-Broker", $Broker,
    "-HttpPort", $HttpPort,
    "-MqttUser", $MqttUser
)
if ($LanIp) { $forward += @("-LanIp", $LanIp) }
if ($BinPath) { $forward += @("-BinPath", $BinPath) }
if ($MqttPassword) { $forward += @("-MqttPassword", $MqttPassword) }
if ($AllowFirewall) { $forward += "-AllowFirewall" }

& powershell @forward
exit $LASTEXITCODE
