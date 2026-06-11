#!/usr/bin/env bash
# Valida presença (LWT) e heartbeat — requer broker MQTT e device_id.
# Uso: BROKER=192.168.1.100 DEVICE_ID=aabbccddeeff ./scripts/bench_mqtt_telemetry.sh
set -euo pipefail

BROKER="${BROKER:-192.168.1.100}"
DEVICE_ID="${DEVICE_ID:?Defina DEVICE_ID (12 hex chars)}"
TIMEOUT="${TIMEOUT:-45}"

echo "Assinando sirene/${DEVICE_ID}/presenca e heartbeat por ${TIMEOUT}s..."
timeout "$TIMEOUT" mosquitto_sub -h "$BROKER" -v \
  -t "sirene/${DEVICE_ID}/presenca" \
  -t "sirene/${DEVICE_ID}/heartbeat" \
  || true

echo "Verifique: presenca=online (retained) e heartbeat JSON periodico."
