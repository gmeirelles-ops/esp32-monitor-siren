#!/usr/bin/env bash
# Dispara OTA_UPDATE via MQTT — requer broker, device_id e URL do binario.
# Uso: BROKER=192.168.1.100 DEVICE_ID=... OTA_URL=http://.../sirene-validator.bin ./scripts/bench_ota.sh
set -euo pipefail

BROKER="${BROKER:-192.168.1.100}"
DEVICE_ID="${DEVICE_ID:?Defina DEVICE_ID}"
OTA_URL="${OTA_URL:?Defina OTA_URL}"

PAYLOAD=$(printf '{"cmd":"OTA_UPDATE","url":"%s"}' "$OTA_URL")

echo "Publicando OTA_UPDATE em sirene/${DEVICE_ID}/comando"
mosquitto_pub -h "$BROKER" -q 1 \
  -t "sirene/${DEVICE_ID}/comando" \
  -m "$PAYLOAD"

echo "Assinando status por 120s..."
timeout 120 mosquitto_sub -h "$BROKER" -v \
  -t "sirene/${DEVICE_ID}/status" \
  -t "sirene/${DEVICE_ID}/heartbeat" \
  || true

echo "Verifique eventos tipo:ota (inicio/sucesso/falha) e nova firmware_version no heartbeat."
