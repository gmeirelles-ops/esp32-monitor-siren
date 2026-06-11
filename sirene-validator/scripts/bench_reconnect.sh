#!/usr/bin/env bash
# Monitora heartbeat durante teste de reconexao (corte de Wi-Fi/broker manual).
# Uso: BROKER=192.168.1.100 DEVICE_ID=... ./scripts/bench_reconnect.sh
set -euo pipefail

BROKER="${BROKER:-192.168.1.100}"
DEVICE_ID="${DEVICE_ID:?Defina DEVICE_ID}"

echo "Monitore heartbeat e presenca. Corte o roteador ou broker por ~30s e religue."
echo "Pressione Ctrl+C para encerrar."
mosquitto_sub -h "$BROKER" -v \
  -t "sirene/${DEVICE_ID}/presenca" \
  -t "sirene/${DEVICE_ID}/heartbeat" \
  -t "sirene/${DEVICE_ID}/status"
