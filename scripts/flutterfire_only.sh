#!/usr/bin/env bash
# Só reconfigura FlutterFire (se setup_firebase falhou nesta etapa)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$ROOT/scripts/bin:$PATH:${HOME}/.pub-cache/bin"
PROJECT_ID="${FIREBASE_PROJECT_ID:-monitor-sirenv2-6d201}"

[[ -x "$ROOT/scripts/node_modules/.bin/firebase" ]] || (cd "$ROOT/scripts" && npm install --no-fund --no-audit)
command -v flutterfire >/dev/null 2>&1 || dart pub global activate flutterfire_cli

firebase --version
firebase projects:list | grep "$PROJECT_ID" || {
  echo "ERRO: faça login sem sudo: npx -y firebase-tools@latest login"
  exit 1
}

cd "$ROOT/sirene_app"
flutterfire configure --project="$PROJECT_ID" --platforms=windows,android --yes
flutter pub get && dart run build_runner build
echo "✓ FlutterFire OK"
