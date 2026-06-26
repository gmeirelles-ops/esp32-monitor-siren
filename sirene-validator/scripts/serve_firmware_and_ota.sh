#!/usr/bin/env bash
# Serve sirene-validator.bin via HTTP e dispara OTA_UPDATE via MQTT.
# Uso: DEVICE_ID=841fe83a5db4 ./scripts/serve_firmware_and_ota.sh
set -euo pipefail

BROKER="${BROKER:-192.168.51.87}"
DEVICE_ID="${DEVICE_ID:?Defina DEVICE_ID}"
HTTP_PORT="${HTTP_PORT:-8080}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_BIN="${PROJECT_ROOT}/build/sirene-validator.bin"
SERVE_DIR="${SERVE_DIR:-/tmp/sv_ota_serve}"

if [[ ! -f "$BUILD_BIN" ]]; then
  echo "Binário não encontrado: $BUILD_BIN"
  echo "Execute: idf.py build"
  exit 1
fi

mkdir -p "$SERVE_DIR"
cp "$BUILD_BIN" "$SERVE_DIR/sirene-validator.bin"

LAN_IP="${LAN_IP:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
if [[ -z "$LAN_IP" ]]; then
  echo "Não foi possível detectar LAN_IP — defina manualmente: LAN_IP=192.168.x.x"
  exit 1
fi

OTA_URL="http://${LAN_IP}:${HTTP_PORT}/sirene-validator.bin"
PAYLOAD=$(printf '{"cmd":"OTA_UPDATE","url":"%s"}' "$OTA_URL")

echo "Servindo ${SERVE_DIR} em http://${LAN_IP}:${HTTP_PORT}/"
python3 -m http.server "$HTTP_PORT" --directory "$SERVE_DIR" &
HTTP_PID=$!
trap 'kill "$HTTP_PID" 2>/dev/null || true' EXIT

sleep 1

echo "Publicando OTA_UPDATE em sirene/${DEVICE_ID}/comando"
echo "URL: ${OTA_URL}"
mosquitto_pub -h "$BROKER" -q 1 \
  -t "sirene/${DEVICE_ID}/comando" \
  -m "$PAYLOAD"

echo "Monitorando status e heartbeat por 120s..."
timeout 120 mosquitto_sub -h "$BROKER" -v \
  -t "sirene/${DEVICE_ID}/status" \
  -t "sirene/${DEVICE_ID}/heartbeat" \
  || true

echo "Verifique eventos tipo:ota e firmware_version no heartbeat."
