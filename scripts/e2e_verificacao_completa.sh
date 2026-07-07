#!/usr/bin/env bash
# Verificação ponta a ponta: operador Firebase + produto no app + eventos MQTT.
#
# Uso (Linux — testa app local + MQTT; Firestore só no build Windows):
#   ./scripts/e2e_verificacao_completa.sh
#
# Variáveis opcionais:
#   BROKER=192.168.51.87
#   MQTT_SITE=producao
#   BANCADA=03              — número da bancada (1–99)
#   DEVICE_ID=bancada-03    — legado; derivado de BANCADA se omitido
#   SKIP_MQTT=1             — só mostra checklist
#   CREATE_OPERATOR=1       — tenta criar operador via Auth API
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BROKER="${BROKER:-192.168.51.87}"
MQTT_SITE="${MQTT_SITE:-producao}"
BANCADA="${BANCADA:-03}"
BANCADA_PADDED="$(printf '%02d' "$BANCADA")"
TOPIC_BASE="${MQTT_SITE}/bancada-${BANCADA_PADDED}"
DEVICE_ID="${DEVICE_ID:-bancada-${BANCADA_PADDED}}"
PROJECT_ID="${FIREBASE_PROJECT_ID:-monitor-sirenv2-6d201}"
API_KEY="${FIREBASE_API_KEY:-AIzaSyDPty7URXLaLyyvqQUSYZOXmreq-Ql__bg}"

# Dados do teste de fábrica (ajuste se necessário)
NUMERO_OP="${NUMERO_OP:-0001}"
ID_PRODUTO="${ID_PRODUTO:-072}"
ANO="${ANO:-26}"
SEQUENCIAL="${SEQUENCIAL:-500}"
STATION_ID="${STATION_ID:-posto-D1}"

OPERATOR_EMAIL="${OPERATOR_EMAIL:-operador.teste@diponto.com.br}"
OPERATOR_PASSWORD="${OPERATOR_PASSWORD:-SireneTeste2026!}"

PRODUCT_NOME="${PRODUCT_NOME:-Sirene produto 072 E2E}"

echo "=============================================="
echo " E2E Diponto Sirene — verificação completa"
echo "=============================================="
echo "Broker MQTT:  $BROKER"
echo "Tópico base:  $TOPIC_BASE/"
echo "Device ID:    $DEVICE_ID"
echo "Firebase:     $PROJECT_ID"
echo "OP / produto: $NUMERO_OP / $ID_PRODUTO"
echo ""

step() { echo ""; echo "▶ $1"; echo "----------------------------------------------"; }

# --- 1. Operador Firebase ---
step "1. Operador Firebase Authentication"
echo "E-mail:    $OPERATOR_EMAIL"
echo "Senha:     $OPERATOR_PASSWORD"
echo ""
if [[ "${CREATE_OPERATOR:-}" == "1" ]]; then
  echo "Tentando criar operador via API..."
  RESP=$(curl -s -X POST \
    "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${OPERATOR_EMAIL}\",\"password\":\"${OPERATOR_PASSWORD}\",\"returnSecureToken\":true}" || true)
  if echo "$RESP" | grep -q '"idToken"'; then
    echo "✓ Operador criado com sucesso"
  elif echo "$RESP" | grep -q 'EMAIL_EXISTS'; then
    echo "✓ Operador já existe (EMAIL_EXISTS)"
  else
    echo "✗ Não foi possível criar via API. Crie manualmente:"
    echo "  https://console.firebase.google.com/project/${PROJECT_ID}/authentication/users"
    echo "  Resposta: $RESP"
  fi
else
  echo "Crie no Console (se ainda não existir):"
  echo "  https://console.firebase.google.com/project/${PROJECT_ID}/authentication/providers"
  echo "  → E-mail/senha ATIVADO"
  echo "  https://console.firebase.google.com/project/${PROJECT_ID}/authentication/users"
  echo "  → Adicionar usuário: $OPERATOR_EMAIL"
  echo ""
  echo "Ou rode: CREATE_OPERATOR=1 $0"
fi

# --- 2. Produto no app ---
step "2. Produto no app Flutter"
echo "No app → Produtos → Novo produto:"
echo "  ID produto:     $ID_PRODUTO"
echo "  Nome:           $PRODUCT_NOME"
echo "  Tolerância:     10 %"
echo "  Tempo teste:    10 s"
echo "  Potência ref:   39,58 W  (ou use autocalibração)"
echo "  Min / Max:      35,62 / 43,54 W"
echo ""
echo "Linux: grava só no SQLite local."
echo "Windows + sync: Configurações → Nuvem → login → sync ON →"
echo "  'Enviar catálogo para Firestore'"

# --- 3. App config ---
step "3. Configurações do app"
echo "  Broker MQTT:  $BROKER : 1883"
echo "  station_id:   $STATION_ID"
echo "  (Windows) Sync Firestore + login: $OPERATOR_EMAIL"

if [[ "${SKIP_MQTT:-}" == "1" ]]; then
  echo ""
  echo "SKIP_MQTT=1 — pulando publicações MQTT"
  exit 0
fi

if ! command -v mosquitto_pub >/dev/null 2>&1; then
  echo "ERRO: instale mosquitto-clients (mosquitto_pub)"
  exit 1
fi

# --- 4. MQTT SET_BATCH ---
step "4. MQTT — SET_BATCH (simula lote configurado)"
SET_BATCH_JSON=$(cat <<EOF
{"cmd":"SET_BATCH","numero_op":"${NUMERO_OP}","id_produto":"${ID_PRODUTO}","ano":"${ANO}","tempo_teste":10,"potencia_min":35.62,"potencia_max":43.54,"quantidade_total":108,"proximo_sequencial":${SEQUENCIAL},"modo_reteste":false}
EOF
)
echo "$SET_BATCH_JSON"
mosquitto_pub -h "$BROKER" -t "${TOPIC_BASE}/comando" -m "$SET_BATCH_JSON"
echo "✓ Publicado em ${TOPIC_BASE}/comando"
sleep 1

# --- 5. Heartbeat ---
step "5. MQTT — heartbeat (dispositivo online)"
HB_JSON='{"uptime":3600,"rssi":-58,"estado":"BATCH_READY","fila":0,"firmware_version":"1.7.5","bancada":'"${BANCADA}"'}'
mosquitto_pub -h "$BROKER" -t "${TOPIC_BASE}/heartbeat" -m "$HB_JSON"
echo "✓ Publicado heartbeat BATCH_READY (firmware 1.7.5)"

# --- 6. Resultado teste ---
step "6. MQTT — resultado de teste APROVADO"
TEST_JSON=$(cat <<EOF
{"tipo":"teste","numero_op":"${NUMERO_OP}","id_produto":"${ID_PRODUTO}","ano":"${ANO}","veredito":"APROVADO","potencia_media":39.58,"sequencial":${SEQUENCIAL},"aprovados_no_lote":1,"bancada":${BANCADA}}
EOF
)
echo "$TEST_JSON"
mosquitto_pub -h "$BROKER" -t "${TOPIC_BASE}/status" -m "$TEST_JSON"
echo "✓ Publicado em ${TOPIC_BASE}/status"

# --- 7. Verificação ---
step "7. O que verificar"
echo "NO APP (com MQTT conectado ao broker $BROKER):"
echo "  □ Dispositivo $DEVICE_ID aparece em Dispositivos"
echo "  □ Estado BATCH_READY / último teste APROVADO"
echo "  □ Produto $ID_PRODUTO na lista Produtos"
echo "  □ Histórico local com OP $NUMERO_OP"
echo ""
echo "NO FIRESTORE (somente build Windows + sync ligado):"
echo "  https://console.firebase.google.com/project/${PROJECT_ID}/firestore"
echo "  □ products/${ID_PRODUTO}"
echo "  □ test_results/${NUMERO_OP} (documento lote)"
echo "  □ test_results/${NUMERO_OP}/seriais/{serial}"
echo "  □ devices/${DEVICE_ID}"
echo "  □ batches/${NUMERO_OP}"
echo ""
echo "Configurações → Nuvem:"
echo "  □ Pendentes: 0 | Último sync: horário recente"
echo ""
echo "✓ Script MQTT concluído. App deve estar aberto e conectado ao broker."
