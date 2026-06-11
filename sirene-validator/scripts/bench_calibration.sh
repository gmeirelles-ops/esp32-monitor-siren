#!/usr/bin/env bash
# Smoke test de calibração MQTT — requer ESP32 em IDLE e peça na bancada.
set -euo pipefail

BROKER="${BROKER:-192.168.1.100}"
DEVICE_ID="${DEVICE_ID:?Defina DEVICE_ID}"

echo "Assinando sirene/$DEVICE_ID/calibracao ..."
timeout 15 mosquitto_sub -h "$BROKER" -v -t "sirene/$DEVICE_ID/calibracao" &
SUB_PID=$!
sleep 1

echo "Enviando START_CALIBRATION ..."
mosquitto_pub -h "$BROKER" -q 1 \
  -t "sirene/$DEVICE_ID/comando" \
  -m '{"cmd":"START_CALIBRATION"}'

wait "$SUB_PID" || true
echo "Concluído — verifique amostras calibracao_amostra e final calibracao."
