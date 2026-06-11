#!/usr/bin/env bash
# Setup Firebase — projeto monitor-sirenv2-6d201
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ID="${FIREBASE_PROJECT_ID:-monitor-sirenv2-6d201}"
REGION="${FIREBASE_REGION:-southamerica-east1}"
FB=""
export PATH="$ROOT/scripts/bin:$PATH:${HOME}/.pub-cache/bin"

has_tokens() {
  local file="$1"
  python3 -c "import json,sys; d=json.load(open('$file')); sys.exit(0 if 'tokens' in d else 1)" 2>/dev/null
}

sync_user_creds_from_root() {
  local root_cfg="/root/.config/configstore/firebase-tools.json"
  local user_cfg="$HOME/.config/configstore/firebase-tools.json"
  if sudo test -f "$root_cfg"; then
    mkdir -p "$HOME/.config/configstore"
    sudo cp "$root_cfg" "$user_cfg"
    sudo chown "$(id -u):$(id -g)" "$user_cfg"
    chmod 600 "$user_cfg"
    echo "==> Credenciais Firebase copiadas de /root para o usuário"
  fi
}

firebase_options_ready() {
  local opts="$ROOT/sirene_app/lib/firebase_options.dart"
  [[ -f "$opts" ]] && grep -q "projectId: '$PROJECT_ID'" "$opts"
}

project_exists() {
  local list
  if ! list=$($FB projects:list 2>&1); then
    echo "$list" >&2
    return 1
  fi
  echo "$list" | grep -qE "${PROJECT_ID}(\s|\)|$)"
}

pick_fb() {
  if [[ "${FIREBASE_USE_SUDO:-}" == "1" ]]; then
    FB="sudo $ROOT/scripts/bin/firebase"
    echo "==> Firebase CLI com sudo"
    return
  fi

  if has_tokens "$HOME/.config/configstore/firebase-tools.json"; then
    if "$ROOT/scripts/bin/firebase" projects:list >/dev/null 2>&1; then
      FB="$ROOT/scripts/bin/firebase"
      echo "==> Firebase CLI: usuário"
      return
    fi
    echo "AVISO: token do usuário existe mas CLI falhou — sincronizando de /root..."
    sync_user_creds_from_root
    if "$ROOT/scripts/bin/firebase" projects:list >/dev/null 2>&1; then
      FB="$ROOT/scripts/bin/firebase"
      echo "==> Firebase CLI: usuário (após sync)"
      return
    fi
  else
    sync_user_creds_from_root
    if has_tokens "$HOME/.config/configstore/firebase-tools.json" && \
       "$ROOT/scripts/bin/firebase" projects:list >/dev/null 2>&1; then
      FB="$ROOT/scripts/bin/firebase"
      echo "==> Firebase CLI: usuário"
      return
    fi
  fi

  if sudo "$ROOT/scripts/bin/firebase" projects:list >/dev/null 2>&1; then
    FB="sudo $ROOT/scripts/bin/firebase"
    echo "==> Firebase CLI com sudo"
    return
  fi

  echo "ERRO: não foi possível executar Firebase CLI."
  echo "Tente: npx -y firebase-tools@latest login   (sem sudo)"
  exit 1
}

run_flutterfire() {
  echo "==> FlutterFire configure..."
  command -v flutterfire >/dev/null 2>&1 || dart pub global activate flutterfire_cli

  if ! firebase --version >/dev/null 2>&1; then
    echo "ERRO: comando 'firebase' não disponível no PATH."
    echo "PATH deve incluir: $ROOT/scripts/bin"
    exit 1
  fi

  if ! firebase projects:list 2>/dev/null | grep -q "$PROJECT_ID"; then
    echo "ERRO: FlutterFire precisa listar projetos como seu usuário."
    echo "Rode: npx -y firebase-tools@latest login"
    exit 1
  fi

  cd "$ROOT/sirene_app"
  flutterfire configure \
    --project="$PROJECT_ID" \
    --platforms=windows,android \
    --yes

  flutter pub get
  dart run build_runner build
}

echo "==> Instalando Firebase CLI local (scripts/node_modules)..."
if [[ ! -x "$ROOT/scripts/node_modules/.bin/firebase" ]]; then
  (cd "$ROOT/scripts" && npm install --no-fund --no-audit)
fi

echo "==> Projeto: $PROJECT_ID | Região: $REGION"
pick_fb

if ! project_exists; then
  echo "ERRO: projeto $PROJECT_ID não encontrado."
  exit 1
fi
echo "==> Projeto $PROJECT_ID encontrado"

cd "$ROOT"

cat > "$ROOT/.firebaserc" <<EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF

$FB use "$PROJECT_ID"

if ! $FB firestore:databases:list 2>/dev/null | grep -q "(default)"; then
  echo "==> Criando Firestore Standard em $REGION..."
  $FB firestore:databases:create "(default)" --location="$REGION" --edition=standard
else
  echo "==> Firestore (default) já existe"
fi

echo "==> Deploy rules + indexes..."
$FB deploy --only firestore

if firebase_options_ready; then
  echo "==> firebase_options.dart já configurado para $PROJECT_ID — pulando FlutterFire"
else
  run_flutterfire
fi

echo ""
echo "✓ Setup concluído para $PROJECT_ID"
echo "Console: https://console.firebase.google.com/project/$PROJECT_ID/overview"
