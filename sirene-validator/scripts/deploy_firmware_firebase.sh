#!/usr/bin/env bash
# Copia o .bin para Firebase Hosting, faz deploy e publica o canal MQTT auto-OTA.
#
# Uso:
#   ./scripts/deploy_firmware_firebase.sh
#   ./scripts/deploy_firmware_firebase.sh --version 1.8.20 --bin /tmp/sv_build/sirene-validator.bin
#   ./scripts/deploy_firmware_firebase.sh --no-mqtt   # só hosting
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SV="$ROOT/sirene-validator"
HOSTING_FW="$ROOT/firebase/hosting/public/firmware"
DEFAULT_BIN="/tmp/sv_build/sirene-validator.bin"
FALLBACK_BIN="$SV/build/sirene-validator.bin"
FIREBASE_URL_BASE="https://monitor-sirenv2-6d201.web.app"
BIN_URL="${FIREBASE_URL_BASE}/firmware/sirene-validator.bin"

VERSION=""
BIN=""
DO_MQTT=1
DO_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --bin) BIN="$2"; shift 2 ;;
    --no-mqtt) DO_MQTT=0; shift ;;
    --build) DO_BUILD=1; shift ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *) echo "Arg desconhecido: $1" >&2; exit 1 ;;
  esac
done

if [[ $DO_BUILD -eq 1 ]]; then
  # shellcheck disable=SC1090
  source "${IDF_PATH:-$HOME/esp/esp-idf}/export.sh" >/dev/null
  (cd "$SV" && idf.py -B /tmp/sv_build build)
  BIN="/tmp/sv_build/sirene-validator.bin"
fi

if [[ -z "$BIN" ]]; then
  if [[ -f "$DEFAULT_BIN" ]]; then
    BIN="$DEFAULT_BIN"
  elif [[ -f "$FALLBACK_BIN" ]]; then
    BIN="$FALLBACK_BIN"
  else
    echo "Binário não encontrado. Passe --bin ou --build" >&2
    exit 1
  fi
fi

if [[ ! -f "$BIN" ]]; then
  echo "Arquivo inexistente: $BIN" >&2
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  VERSION="$(grep -E '^#define FIRMWARE_VERSION' \
    "$SV/components/board_config/include/board_config.h" \
    | sed -E 's/.*"([^"]+)".*/\1/')"
fi

mkdir -p "$HOSTING_FW"
cp -f "$BIN" "$HOSTING_FW/sirene-validator.bin"
SIZE="$(wc -c < "$HOSTING_FW/sirene-validator.bin" | tr -d ' ')"

cat > "$HOSTING_FW/version.json" <<EOF
{
  "version": "$VERSION",
  "url": "$BIN_URL",
  "size_bytes": $SIZE,
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "Deploy Firebase Hosting (firmware $VERSION, ${SIZE} bytes)…"
cd "$ROOT"
npx -y firebase-tools@latest deploy --only hosting --project monitor-sirenv2-6d201

echo "URL: $BIN_URL"
curl -sI --connect-timeout 15 "$BIN_URL" | head -8 || true

if [[ $DO_MQTT -eq 1 ]]; then
  echo "Publicando canal MQTT producao/firmware/atual …"
  python3 "$SV/scripts/publish_firmware_channel.py" \
    --version "$VERSION" \
    --url "$BIN_URL"
fi

echo "OK — bancadas com firmware >= 1.8.20 atualizam no próximo boot se a versão local for diferente."
