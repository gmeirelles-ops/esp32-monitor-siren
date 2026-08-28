#!/usr/bin/env bash
# Validação automatizada + checklist manual firmware × app (001-fw-sw-compat).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/sirene_app"
FW_HOST="$ROOT/sirene-validator/host_tests"

echo "=== Diponto — Compatibilidade FW × SW ==="
echo ""

echo ">> [auto] Testes Flutter (parser MQTT, protocolo, métricas)..."
(cd "$APP" && flutter test \
  test/mqtt_parser_test.dart \
  test/mqtt_status_parser_test.dart \
  test/mqtt_topics_test.dart \
  test/mqtt_protocol_test.dart \
  test/mqtt_pipeline_hardening_test.dart \
  test/mqtt_verdict_trust_test.dart)

echo ""
echo ">> [auto] Host tests firmware (lógica pura)..."
if [[ -d "$FW_HOST" ]]; then
  (cd "$FW_HOST" && cmake -B build -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build build >/dev/null && ctest --test-dir build --output-on-failure)
else
  echo "   (pulado: $FW_HOST não encontrado)"
fi

echo ""
echo "=== Checklist manual na bancada (marque OK) ==="
cat <<'EOF'

Pré-requisitos: firmware ≥1.8.11 flashado, app atual, broker MQTT, produto cadastrado.

| # | Passo | OK? |
|---|-------|-----|
| 1 | mosquitto_sub em producao/bancada-NN/# — tópicos bancada-NN | |
| 2 | Heartbeat contém protocol_version: 1 | |
| 3 | INICIAR lote → heartbeat BATCH_READY em ≤10 s | |
| 4 | Teste aprovado → tipo:teste APROVADO → serial ITF no app | |
| 5 | Teste reprovado → sem serial | |
| 6 | quantidade_total:1 → 2º teste → rejeicao lote_cheio visível | |
| 7 | Modo reteste → aprovação sem serial | |
| 8 | Simular batch_nvs_fault → banner NVS no lote ao vivo | |
| 9 | App protocolo 1 + fw antigo sem campo → sem banner vermelho | |
| 10 | Desligar Wi-Fi → testar → reconectar → dedupe ts_ms ok | |

Referência completa: specs/001-fw-sw-compat/quickstart.md

EOF

echo "=== Fim — testes automatizados OK ==="
