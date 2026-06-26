#Requires -Version 5.1
<#
.SYNOPSIS
  Testa servidor TCP laser do app Sirene (simula DiatuCAD).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\test_laser_tcp.ps1
  powershell -ExecutionPolicy Bypass -File scripts\test_laser_tcp.ps1 -Port 9101 -Command "TCP: Give me string"
#>
param(
    [int]$Port = 9101,
    [string]$Command = "TCP: Give me string",
    [string]$Host = "127.0.0.1",
    [int]$ReadTimeoutMs = 3000
)

$ErrorActionPreference = "Stop"

Write-Host "==> Conectando em ${Host}:${Port}"
Write-Host "    Comando: $Command"

$client = New-Object System.Net.Sockets.TcpClient
try {
    $connect = $client.BeginConnect($Host, $Port, $null, $null)
    if (-not $connect.AsyncWaitHandle.WaitOne(5000)) {
        throw "Timeout ao conectar. O app esta em modo Gravação laser e salvo?"
    }
    $client.EndConnect($connect)

    $stream = $client.GetStream()
    $stream.ReadTimeout = $ReadTimeoutMs
    $bytes = [Text.Encoding]::ASCII.GetBytes($Command)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    $buf = New-Object byte[] 256
    $n = $stream.Read($buf, 0, $buf.Length)
    if ($n -le 0) {
        Write-Host "Resposta: (vazia)"
        exit 2
    }

    $response = [Text.Encoding]::ASCII.GetString($buf, 0, $n).Trim()
    Write-Host "Resposta: $response"

    if ($response.StartsWith("ERROR:")) {
        exit 1
    }
    exit 0
}
catch {
    Write-Host "Falha: $_"
    exit 2
}
finally {
    if ($client.Connected) {
        $client.Close()
    }
}
