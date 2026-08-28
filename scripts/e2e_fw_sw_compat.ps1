#Requires -Version 5.1
<#
.SYNOPSIS
  Validação automatizada + checklist manual firmware × app (001-fw-sw-compat).

.DESCRIPTION
  Rode no PC Windows do posto antes do checklist físico na bancada.
  Executa testes Flutter de contrato MQTT; host tests do firmware são opcionais
  (requer CMake no PATH).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\e2e_fw_sw_compat.ps1
#>
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (Test-Path (Join-Path $PSScriptRoot "windows_build_common.ps1")) {
    . (Join-Path $PSScriptRoot "windows_build_common.ps1")
    try {
        $RepoRoot = Ensure-WindowsAsciiRepoPath
    } catch {
        # Repo já em caminho ASCII — segue com $RepoRoot
    }
}

$AppDir = Join-Path $RepoRoot "sirene_app"
$FwHost = Join-Path $RepoRoot "sirene-validator\host_tests"

Write-Host "=== Diponto — Compatibilidade FW × SW (Windows) ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter não encontrado no PATH. Instale Flutter e reinicie o terminal."
}

Write-Host ">> [auto] Testes Flutter (parser MQTT, protocolo)..." -ForegroundColor Yellow
Push-Location $AppDir
try {
    flutter test `
        test/mqtt_parser_test.dart `
        test/mqtt_status_parser_test.dart `
        test/mqtt_topics_test.dart `
        test/mqtt_protocol_test.dart `
        test/mqtt_pipeline_hardening_test.dart `
        test/mqtt_verdict_trust_test.dart
    if ($LASTEXITCODE -ne 0) { throw "flutter test falhou (exit $LASTEXITCODE)" }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host ">> [auto] Host tests firmware (opcional, requer CMake)..." -ForegroundColor Yellow
if ((Test-Path $FwHost) -and (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Push-Location $FwHost
    try {
        cmake -B build -DCMAKE_BUILD_TYPE=Release | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "cmake configure falhou" }
        cmake --build build --config Release | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "cmake build falhou" }
        ctest --test-dir build -C Release --output-on-failure
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Host tests falharam — revise no Linux/CI se necessário; checklist físico pode continuar."
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "   (pulado: CMake ou pasta host_tests ausente)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=== Checklist manual na bancada (marque OK) ===" -ForegroundColor Cyan
Write-Host @"

Pré-requisitos neste PC:
  - Firmware >= 1.8.11 flashado na ESP32
  - App Diponto atual (flutter run -d windows ou instalador)
  - Broker MQTT acessível (mesma rede do posto)
  - Produto cadastrado no app

Ferramentas úteis no Windows:
  - MQTT Explorer (ver tópicos) — ver scripts\E2E_MQTT_EXPLORER.md
  - Assinar: producao/bancada-NN/#  (substitua NN pela bancada)

| # | Passo | OK? |
|---|-------|-----|
| 1 | MQTT Explorer: tópicos producao/bancada-NN/... (não sirene/MAC) | |
| 2 | Heartbeat JSON contém "protocol_version": 1 | |
| 3 | App: INICIAR lote → heartbeat estado BATCH_READY em <=10 s | |
| 4 | Botão bancada: aprovado → app gera serial ITF 10 dígitos | |
| 5 | Reprovado (fora da faixa) → sem serial | |
| 6 | quantidade_total: 1 → 2º teste → rejeicao lote_cheio visível | |
| 7 | Modo reteste ON → aprovação sem serial | |
| 8 | batch_nvs_fault (se simulável) → banner NVS no lote ao vivo | |
| 9 | Firmware antigo sem protocol_version → sem banner vermelho | |
| 10 | Wi-Fi off → 1 teste → reconectar → sem duplicar contador | |

Comandos rápidos neste PC:
  cd sirene_app
  flutter run -d windows
  # ou, se caminho com acento:
  powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 run -d windows

Referência: specs\001-fw-sw-compat\quickstart.md

"@

Write-Host "=== Fim — testes automatizados OK ===" -ForegroundColor Green
Write-Host "Execute o checklist manual acima na bancada conectada a este PC." -ForegroundColor Green
