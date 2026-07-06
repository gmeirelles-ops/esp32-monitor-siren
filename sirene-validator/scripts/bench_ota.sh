#!/usr/bin/env bash
# Dispara OTA_UPDATE via MQTT — requer broker, bancada e URL do binario.
# Uso: BROKER=mqtt.diponto.com BANCADA=1 OTA_URL=http://.../sirene-validator.bin ./scripts/bench_ota.sh
set -euo pipefail

BROKER="${BROKER:-mqtt.diponto.com}"
SITE="${SITE:-producao}"
BANCADA="${BANCADA:?Defina BANCADA (1-99)}"
OTA_URL="${OTA_URL:?Defina OTA_URL}"
MQTT_USER="${MQTT_USER:-}"
MQTT_PASS="${MQTT_PASS:-}"

BANCADA_SLUG=$(printf 'bancada-%02d' "$BANCADA")
TOPIC="${SITE}/${BANCADA_SLUG}/comando"
PAYLOAD=$(printf '{"cmd":"OTA_UPDATE","url":"%s"}' "$OTA_URL")

AUTH_ARGS=()
if [[ -n "$MQTT_USER" ]]; then
  AUTH_ARGS+=(-u "$MQTT_USER" -P "$MQTT_PASS")
fi

echo "Publicando OTA_UPDATE em ${TOPIC}"
mosquitto_pub -h "$BROKER" -p "${MQTT_PORT:-443}" "${AUTH_ARGS[@]}" --cafile "${MQTT_CAFILE:-}" -q 1 \
  -t "$TOPIC" \
  -m "$PAYLOAD"

echo "Assinando status por 120s..."
timeout 120 mosquitto_sub -h "$BROKER" -p "${MQTT_PORT:-443}" "${AUTH_ARGS[@]}" -v \
  -t "${SITE}/${BANCADA_SLUG}/status" \
  -t "${SITE}/${BANCADA_SLUG}/heartbeat" \
  || true

echo "Verifique eventos tipo:ota (inicio/sucesso/falha) e nova firmware_version no heartbeat."
